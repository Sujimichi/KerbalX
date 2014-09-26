module KerbalX
  class IgnoreFile

    def initialize path

      ignore_file = File.join([path, "partmapper.ignore"])
      if File.exists?(ignore_file)
        ignore_data = File.open(ignore_file, "r"){|f| f.readlines}.select{|line| 
          !line.match(/^#/)
        }.map{|line| line.strip}.select{|line| !line.blank?}
        
        dirs = Dir.entries(File.join([path, "GameData"]))
        @ignore = ignore_data.select{|ig| dirs.include?(ig)}
        
        if @ignore != ignore_data
          msg = "\n\nAn entry in your partmapper.ignore does not match a folder in GameData"
          no_match = ignore_data - @ignore
          msg << "\n#{no_match.join (", ")} can't be found"
          msg << "\nentires in partmapper.ignore need to EXACTLY match folders found in GameData"
          raise msg #hmmmm, MSG
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
