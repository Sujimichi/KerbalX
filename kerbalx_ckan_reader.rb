#This script runs the CKAN-meta reading actions
#under construction, testing, not for general consumption, if swallowed seek medical attention.

testing = true

if testing
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "version")      #version info
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "extensions")   #adds some rails methods (ie .blank?) to core classes (String, Array and NilClass).
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "part_parser")  #main part reading logic
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "logger")       #error logger
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "auth_token")   #auth key reader
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "interface")    #interface with KerbalX.com
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "ignore_file")  #read any user deifned mods to be ignored
  require File.join(File.dirname(__FILE__), "lib", "KerbalX", "ckan_reader")  
else
  require 'KerbalX'
end


puts "\nCKAN-Meta Reader for KerbalX.com - v#{KerbalX::VERSION}\n\n"

@site = "http://localhost:3000"
#@site = "http://kerbalx.com"
#@site = "http://kerbalx-stage.herokuapp.com"

@path = "/home/sujimichi/coding/lab/KerbalX-CKAN" || Dir.getwd

KerbalX::Interface.new(@site, KerbalX::AuthToken.new(@path)) do |kerbalx|

  ckan_reader = CkanReader.new :dir => @path, :interface => kerbalx
  ckan_reader.update_repo 

  ckan_reader.load_mod_data #load mod data from previous runs
  
  ckan_reader.process #download new/updated mods and read part info
  ckan_reader.save_mod_data #write current mod data to file

 
  #send data to KerbalX (using non-indented json)
  ckan_reader.pretty_json = false
  #kerbalx.update_knowledge_base_with_ckan_data ckan_reader.json_data

  unless ckan_reader.errors.empty?
    puts "errors:\n"
    ckan_reader.show_errors
  end
  
end
