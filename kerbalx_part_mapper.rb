require File.join(File.dirname(__FILE__), "lib", "extensions")   #adds some rails methods (ie .blank?) to core classes (String, Array and NilClass).
require File.join(File.dirname(__FILE__), "lib", "part_parser")  #main part reading logic
require File.join(File.dirname(__FILE__), "lib", "system")       #error logger and config opts


require 'KerbalX'
@path = "/home/sujimichi/KSP/KSPv0.24-Stock"
@path = "/home/sujimichi/KSP/KSPv0.24.2-Mod"
parser = KerbalX::PartParser.new(@path, :source => :game_folder, :write_to_file => false)


