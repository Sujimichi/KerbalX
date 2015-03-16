#This script runs the CKAN-meta reading actions
#under construction, testing, not for general consumption, if swallowed seek medical attention.

require 'KerbalX'

puts "\nCKAN-Meta Reader for KerbalX.com - v#{KerbalX::VERSION}\n\n"

#@path = Dir.getwd
@path = "/home/sujimichi/temp"


KerbalX::Interface.new(KerbalX::AuthToken.new(@path)) do |kerbalx|

  ckan_reader = CkanReader.new :dir => @path
  #ckan_reader.update_repo #or clone determining which not implmented yet, manual process atm
  
  #to_process = ckan_reader.to_process
  to_process = ["SCANsat", "Kethane", "BahamutoDynamicsPartsPack", "B9", "InfernalRobotics", "RemoteTech"]

  puts ckan_reader.to_process

  #ckan_reader.process to_process

  #kerbalx.update_knowledge_base_with_ckan_data ckan_reader.mod_data

end
