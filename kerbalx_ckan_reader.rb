#This script runs the CKAN-meta reading actions
#under construction, testing, not for general consumption, if swallowed seek medical attention.


require 'KerbalX'


puts "\nCKAN-Meta Reader for KerbalX.com - v#{KerbalX::VERSION}\n\n".green


@site = "https://kerbalx.com"
#@site = "http://localhost:3000"
#@site = "http://kerbalx-stage.herokuapp.com"


@path = Dir.getwd
#@path = "/home/sujimichi/coding/lab/KerbalX-CKAN" 

KerbalX::Interface.new(@site, KerbalX::AuthToken.new(@path)) do |kerbalx|

  ckan_reader = KerbalX::CkanReader.new :dir => @path, :interface => kerbalx
  
  ckan_reader.update_repo   #fetch updated info from CKAN repo
  ckan_reader.load_data     #load mod data from previous runs
  ckan_reader.process       #download new/updated mods and read part info
  ckan_reader.save_data     #write current mod data to file

  reader_log = {  #get log info to be sent up to KerbalX server    
    :errors => ckan_reader.errors,
    :processed_mods => ckan_reader.processed_mods - ckan_reader.ignore_list,
    :reader_log => ckan_reader.message_log
  }
 
  #send data to KerbalX (using non-indented json)
  ckan_reader.pretty_json = false
  kerbalx.update_knowledge_base_with_ckan_data ckan_reader.json_data(:mod_data), reader_log.to_json

  kerbalx.after_knowledge_base_update do 
    #fetch list of parts without part data
    ckan_reader.msg "Fetching Parts without data from #{kerbalx.site}".blue
    parts_without_data = kerbalx.parts_without_data; nil

    #find data for those parts
    part_data = KerbalX::PartData.new(:reader => ckan_reader, :parts_without_data => parts_without_data);nil
       
    #send part data back to site.
    kerbalx.update_knowledge_base_with_part_data part_data.parts.to_json
        
  end

  unless ckan_reader.errors.empty?
    puts "errors:\n"
    ckan_reader.show_errors
  end


end
