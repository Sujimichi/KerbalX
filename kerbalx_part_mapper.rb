#!/usr/bin/env ruby
#This is the script which is compiled into a .exe by OCRA for use in a windows environment that is devoid of ~joy~ Ruby.


require 'KerbalX'

puts "\nPartMapper for KerbalX.com - v#{KerbalX::VERSION}\n\n".green

@site = "http://kerbalx.com"
#@site = "http://localhost:3000"
#@site = "http://kerbalx-stage.herokuapp.com"

@path = Dir.getwd
#@path = "/home/sujimichi/KSP/KSP_linux" 


#raise error when GameData is not found
unless Dir.entries(@path).include?("GameData")
  raise "\n\nERROR:\nCouldn't find GameData\nMake sure you run PartMapper.exe from the root of your KSP install folder\n".red
end

#read list of mods to ignore
ignore = KerbalX::IgnoreFile.new(@path) if File.exists?(File.join([@path, "ignore_mods.txt"]))

#scan for Parts and transmit to KerbalX with the users auth-token
KerbalX::Interface.new(@site, KerbalX::AuthToken.new(@path)) do |kerbalx|
  puts "Scanning Parts in #{@path}".blue
  puts "These mods will be ignored; #{ignore.join(", ")}".yellow unless ignore.blank?
  puts "\n"
  parser = KerbalX::PartParser.new @path, :ignore_mods => ignore.to_a
  parser.process
  
  puts parser.parts.empty? ? "Did not find any parts, sorry!".yellow : "Discovered #{parser.parts.keys.count} parts".blue
  break if parser.parts.empty?
  puts "\nSending data to KerbalX.com.....\n".blue
  kerbalx.update_knowledge_base_from parser
end

puts "\n\nThis terminal will stay open for a minute if you want to review the output".blue
puts "Or you can close it now with CTRL+C".light_blue
sleep(ENV["OCRA_EXECUTABLE"] ? 60 : 2)

=begin
#rough ideas for future design

KerbalX::Interface.new(KerbalX::AuthToken.new(@path)) do |kerbalx|
  kerbalx.list_craft
  kerbalx.list_users
  kerbalx.get_user("katateochi").list_craft
  kerbalx.get_craft(<craft_id>)
end

=end
