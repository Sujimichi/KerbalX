#This script runs the CKAN-meta reading actions
#under construction, testing, not for general consumption, if swallowed seek medical attention.

#require 'KerbalX'
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "version")      #version info
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "extensions")   #adds some rails methods (ie .blank?) to core classes (String, Array and NilClass).
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "part_parser")  #main part reading logic
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "logger")       #error logger
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "auth_token")   #auth key reader
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "interface")    #interface with KerbalX.com
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "ignore_file")  #read any user deifned mods to be ignored
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "ckan_reader")  


puts "\nCKAN-Meta Reader for KerbalX.com - v#{KerbalX::VERSION}\n\n"

#@path = Dir.getwd
@path = "/home/sujimichi/temp"
@path = "/home/sujimichi/coding/lab/KerbalX-CKAN"


KerbalX::Interface.new(KerbalX::AuthToken.new(@path)) do |kerbalx|

  ckan_reader = CkanReader.new :dir => @path
  ckan_reader.update_repo #or clone determining which not implmented yet, manual process atm

  ckan_reader.load_mod_data #load mod data from previous runs
  
  ckan_reader.process #download new/updated mods and read part info
  ckan_reader.save_mod_data #write current mod data to file
 
  #send data to KerbalX (using non-indented json)
  ckan_reader.pretty_json = false
  response = kerbalx.update_knowledge_base_with_ckan_data ckan_reader.json_data

  
  effected_craft = response["effected_craft_ids"]
  effected_craft = effected_craft.split(",").map{|i| i.to_i}
  unless effected_craft.blank?
    puts "Updating mod info on #{effected_craft.size} craft"
    kerbalx.update_craft effected_craft
  end
  
end
