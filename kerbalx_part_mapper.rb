require File.join(File.dirname(__FILE__), "lib", "KerbalX", "version")      #version info
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "extensions")   #adds some rails methods (ie .blank?) to core classes (String, Array and NilClass).
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "part_parser")  #main part reading logic
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "logger")       #error logger
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "auth_token")   #auth key reader
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "interface")    #interface with KerbalX.com


@path = Dir.getwd
#@path = "/home/sujimichi/KSP/KSPv0.24-Stock"
@path = "/home/sujimichi/KSP/KSPv0.24.2-Mod"
#@path = "/home/sujimichi/KSP/KSPv0.23.0-Mod"

unless Dir.entries(@path).include?("GameData")
  raise "\nERROR:\nCouldn't find GameData\nMake sure you run PartMapper.exe from the root of your KSP install folder"
end

KerbalX::Interface.new(KerbalX::AuthToken.new(@path)) do |kerbalx|
  puts "Scanning Parts in #{@path}"
  parser = KerbalX::PartParser.new @path, :associate_components => false
  puts "done"
  puts parser.parts.empty? ? "Did not find any parts, sorry!" : "Discovered #{parser.parts.keys.count} parts"   
  puts "\nSending data to KerbalX.com.....\n"
  kerbalx.update_knowledge_base_with parser.parts
end

#TODO
#- specs for partmapper when GameData can't be found
#- process for passing in ignored mods

=begin
#rough ideas for future design

KerbalX::Interface.new(KerbalX::AuthToken.new(@path)) do |kerbalx|
  kerbalx.list_craft
  kerbalx.list_users
  kerbalx.get_user("katateochi").list_craft
  kerbalx.get_craft(<craft_id>)
end

=end
