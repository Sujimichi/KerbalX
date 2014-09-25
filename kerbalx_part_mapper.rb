require File.join(File.dirname(__FILE__), "lib", "KerbalX", "extensions")   #adds some rails methods (ie .blank?) to core classes (String, Array and NilClass).
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "part_parser")  #main part reading logic
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "logger")       #error logger and config opts
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "auth_token")   #auth key reader
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "interface")    #interface with KerbalX.com


#require 'KerbalX'
#@path = "/home/sujimichi/KSP/KSPv0.24-Stock"
@path = "/home/sujimichi/KSP/KSPv0.24.2-Mod"

KerbalX::Interface.new(KerbalX::AuthToken.new(@path)) do |kerbalx|
  kerbalx.update_knowledge_base_with KerbalX::PartParser.new(@path).parts
end

#TODO
#- specs for partmapper when GameData can't be found
#- specs for passing in ignored mods
#
