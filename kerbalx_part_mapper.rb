require File.join(File.dirname(__FILE__), "lib", "extensions")   #adds some rails methods (ie .blank?) to core classes (String, Array and NilClass).
require File.join(File.dirname(__FILE__), "lib", "part_parser")  #main part reading logic
require File.join(File.dirname(__FILE__), "lib", "system")       #error logger and config opts



@path = "/home/sujimichi/KSP/KSPv0.24-Stock"
KerbalX::PartParser.new(@path, :source => :game_folder, :write_to_file => false)


