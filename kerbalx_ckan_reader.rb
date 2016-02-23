#This script runs the CKAN-meta reading actions
#under construction, testing, not for general consumption, if swallowed seek medical attention.


=begin
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "version")      #version info
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "extensions")   #adds some rails methods (ie .blank?) to core classes (String, Array and NilClass).
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "part_parser")  #main part reading logic
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "logger")       #error logger
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "auth_token")   #auth key reader
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "interface")    #interface with KerbalX.com
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "ignore_file")  #read any user deifned mods to be ignored
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "ckan_reader")  
=end

require 'KerbalX'


puts "\nCKAN-Meta Reader for KerbalX.com - v#{KerbalX::VERSION}\n\n"

#@site = "http://localhost:3000"
@site = "https://kerbalx.com"
#@site = "http://kerbalx-stage.herokuapp.com"

@path = "/home/sujimichi/coding/lab/KerbalX-CKAN" || Dir.getwd

KerbalX::Interface.new(@site, KerbalX::AuthToken.new(@path)) do |kerbalx|

  ckan_reader = KerbalX::CkanReader.new :dir => @path, :interface => kerbalx
  
  ckan_reader.update_repo   #fetch updated info from CKAN repo
  ckan_reader.load_mod_data #load mod data from previous runs
  ckan_reader.process       #download new/updated mods and read part info
  ckan_reader.save_mod_data #write current mod data to file

  reader_log = {  #get log info to be sent up to KerbalX server    
    :errors => ckan_reader.errors,
    :processed_mods => ckan_reader.processed_mods - ckan_reader.ignore_list,
    :reader_log => ckan_reader.message_log
  }
 
  #send data to KerbalX (using non-indented json)
  ckan_reader.pretty_json = false
  kerbalx.update_knowledge_base_with_ckan_data ckan_reader.json_data, reader_log.to_json

  unless ckan_reader.errors.empty?
    puts "errors:\n"
    ckan_reader.show_errors
  end
  
end
