#This is the script which is compiled into a .exe by OCRA for use in a windows environment that is devoid of ~joy~ Ruby.

require File.join(File.dirname(__FILE__), "lib", "KerbalX", "version")      #version info
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "extensions")   #adds some rails methods (ie .blank?) to core classes (String, Array and NilClass).
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "part_parser")  #main part reading logic
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "logger")       #error logger
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "auth_token")   #auth key reader
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "interface")    #interface with KerbalX.com
require File.join(File.dirname(__FILE__), "lib", "KerbalX", "ignore_file")  #read any user deifned mods to be ignored


puts "\nPartMapper for KerbalX.com - v#{KerbalX::VERSION}\n\n"

@path = Dir.getwd
#@path = "/home/sujimichi/KSP/KSPv0.24-Stock"
#@path = "/home/sujimichi/KSP/KSPv0.24.2-Mod"
#@path = "/home/sujimichi/KSP/KSPv0.23.0-Mod"

#raise error when GameData is not found
unless Dir.entries(@path).include?("GameData")
  raise "\n\nERROR:\nCouldn't find GameData\nMake sure you run PartMapper.exe from the root of your KSP install folder\n"
end

#read list of mods to ignore
ignore = KerbalX::IgnoreFile.new(@path) if File.exists?(File.join([@path, "partmapper.ignore"]))

#main 
KerbalX::Interface.new(KerbalX::AuthToken.new(@path)) do |kerbalx|
  puts "Scanning Parts in #{@path}"
  puts "These mods will be ignored; #{ignore.join(", ")}" unless ignore.blank?
  parser = KerbalX::PartParser.new @path, :associate_components => false, :ignore_mods => ignore.to_a
  puts "done"
  puts parser.parts.empty? ? "Did not find any parts, sorry!" : "Discovered #{parser.parts.keys.count} parts"   
  puts "\nSending data to KerbalX.com.....\n"
  kerbalx.update_knowledge_base_with parser.parts
end

puts "\n\nThis terminal will stay open for 2 minutes if you want to review the output"
puts "Or you can close it now with CTRL+C"
sleep 120

=begin
#rough ideas for future design

KerbalX::Interface.new(KerbalX::AuthToken.new(@path)) do |kerbalx|
  kerbalx.list_craft
  kerbalx.list_users
  kerbalx.get_user("katateochi").list_craft
  kerbalx.get_craft(<craft_id>)
end

=end
