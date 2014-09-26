module KerbalX
  class IgnoreFile

    def initialize path

      ignore_file = File.join([path, "ignore_mods.txt"])
      if File.exists?(ignore_file)
        ignore_data = File.open(ignore_file, "r"){|f| f.readlines}.select{|line| 
          !line.match(/^#/)
        }.map{|line| line.strip}.select{|line| !line.blank? && !line.include?("ExampleModtoSkip") }
        
        dirs = Dir.entries(File.join([path, "GameData"]))
        @ignore = ignore_data.select{|ig| dirs.include?(ig)}
        
        
        if @ignore != ignore_data
          puts "\n\n!!NOTE!!\nAn entry in your partmapper.ignore does not match a folder in GameData"
          no_match = ignore_data - @ignore
          puts  "\n#{no_match.join (", ")} can't be found"         
          puts  "\nentires in partmapper.ignore need to EXACTLY match folders in GameData"
          
          puts "\nIf you want to change the entry in partmapper.ignore then hit CTRL+C now"
          puts "Otherwise I will carry on with the scan in 10 seconds."

          sleep 10
        end
      end
    end

    def join args
      @ignore.join(args)
    end

    def to_a
      @ignore
    end
    def blank?
      @ignore.blank?
    end
  end
end
