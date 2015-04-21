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


KerbalX::Interface.new(KerbalX::AuthToken.new(@path)) do |kerbalx|

  ckan_reader = CkanReader.new :dir => @path
  #ckan_reader.update_repo #or clone determining which not implmented yet, manual process atm
  

  #to_process = ckan_reader.to_process
  to_process = ["SCANsat", "Kethane", "BahamutoDynamicsPartsPack", "B9", "B9AerospaceProceduralParts", "InfernalRobotics", "RemoteTech"]
  to_process << ["KarbonitePlus", "Karbonite", "USI-FTT", "USI-ART", "USI-EXP", "USI-SRV", "CommunityResourcePack", "USITools", "AlcubierreStandalone"]
  to_process << "HullcamVDS"
  to_process.flatten!
  ckan_reader.activity_log = {}

  ckan_reader.process to_process
 
  ckan_reader.pretty_json = false
  kerbalx.update_knowledge_base_with_ckan_data ckan_reader.json_data

end
