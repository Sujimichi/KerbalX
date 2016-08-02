module KerbalX
  class PartParser
    attr_accessor :parts, :resources, :internals, :props, :ignored_cfgs, :logger

    class LegacyPartException  < StandardError; end 
    class UnknownPartException < StandardError; end

    require 'json'

    def initialize dir, args = {}
      defaults = {
        :source => :game_folder,                  #default is to read part info from the GameData folder. Alternative is to read from file.
        :write_to_file => false,                  #if set to true the data will be written to .partDB file (default is partmapper.parts.DB or name can be supplied by :file)
        #:associate_components => true,            #default opt is to associate props, internals and resources with parts (can take time)
        :file => "part_mapper.partsDB",           #default name of file for writing to / reading from
        :stock_parts => ["Squad", "NASAmission"], #defines the default definition of which "mods" are stock
        :logger => KerbalX::Logger.new            #default logger, replace with a logger from the environment PartParser is being used it.
        #:ignore_mods => [mod_dir names to be skipped] optional
      }
      args = defaults.merge(args)

      @args         = args
      @logger       = args[:logger]
      @stock_parts  = args[:stock_parts]
      @instance_dir = dir
      @part_scanner = KerbalX::PartData.new

    end

    def process
      if @args[:source] == :game_folder
        cur_dir = Dir.getwd                     #note the current dir so it can be returned to after running
        Dir.chdir(@instance_dir)                #change into given dir
        begin
          index_parts                           #discover all .cfg files and determine what they defines (Parts, Resources, Props..etc)
          @parts ||= {}                         
          #associate_components if @args[:associate_components] #associate props, internals and resources with parts
          write_to_file if @args[:write_to_file]#optionally, write the data to file
        rescue Exception => e
          @logger.log_error "Failed to build map of installed parts\n#{e}\n#{e.backtrace.first}"
        end      
        Dir.chdir(cur_dir)                      #return to initial dir
      else
        read_from_file 
      end
    end



    def read_from_file 
      data = File.open(File.join([@instance_dir, @args[:file]]),'r'){|f| f.readlines.join }
      parts_from_file = HashWithIndifferentAccess.new(JSON.parse(data))
      @parts = parts_from_file[:parts]
      @resources = parts_from_file[:resources]
      @internals = parts_from_file[:internals]
      @props = parts_from_file[:props]
      @ignored_cfgs = parts_from_file[:ignored_cfgs]
    end

    def write_to_file args 
      File.open(File.join([@instance_dir, @args[:file]]),'w'){|f| f.write self.to_json}
    end

    #find all the .cfg files
    def discover_cfgs
      Dir.glob("**/*/*.cfg")      
    end

    def index_parts 
      part_cfgs = discover_cfgs
      @resources = {}
      #@internals = {}
      #@props = {}
      @ignored_cfgs = []

      count = 0
      part_data = part_cfgs.map do |cfg_path|     
        begin          
          cfg = File.open(cfg_path,"r:bom|utf-8"){|f| f.readlines} #read .cfg file as r:bom|utf-8
        rescue Exception => e
          @logger.log_error "Failed to read #{cfg_path}".red
          @ignored_cfgs << cfg_path          
          next
        end
        

        #if the first attempt fails this is most likely due to a "invalid byte sequence in UTF-8" error. in which case in the rescue we fix the strings in the array 
        #with utf_safe (see Array in extensions.rb) and try again, but also allow for a line to fail and be ignored with rescue false
        #utf_save is not called by default as it results in slower performance
        begin
          first_significant_line = cfg.select{|line| line.match("//").nil? && !line.chomp.empty? }.first #find first line that isn't comments or empty space
        rescue
          cfg = cfg.utf_safe
          first_significant_line = cfg.select{|line| line.match("//").nil? && !line.chomp.empty? rescue false}.first
        end
       
        if first_significant_line.nil?
          @logger.log_error "no significant line found in: #{cfg_path}".yellow 
          next
        end

        next if cfg_path.include?("mechjeb_settings") #not all .cfg files are part files, some are settings, this ignores mechjeb settings (which are numerous). 
        next if cfg_path.match(/^GameData\//) && cfg_path.split("/").size.eql?(2) #ignore cfg files in the root of GameData
        next if cfg_path.match(/^saves\//) #ignore cfg files in saves folder

        begin
          dir = cfg_path.sub("/part.cfg","")
          part_info = {:dir => dir, :path => cfg_path }

          if cfg_path.match(/^GameData/)

            folders = dir.split("/")
            mod_dir = folders[1] #mod dir is the directory inside GameData

            #enables certain mods to be (optionally) skipped
            next if @args[:ignore_mods] && @args[:ignore_mods].include?(mod_dir)

            part_info.merge!(:mod => mod_dir)
            part_info.merge!(:stock => @stock_parts.include?(mod_dir)) 


            #if a cfg contains definitions of resources extra info about the resources.
            if cfg.select{|line| line.match(/^RESOURCE_DEFINITION/)}.first
              @part_scanner.get_part_modules(cfg, "RESOURCE_DEFINITION").map do |resource|            
                resource_attrs = @part_scanner.read_attributes_from resource, ["name", "density", "unitCost", "volume"]                
                resource_name = resource_attrs["name"]
                resource_attrs.delete("name")            
                @resources[mod_dir] ||= {}
                @resources[mod_dir][resource_name] = resource_attrs
              end
            end
            
            #if cfg contains PART then split it on instances of PART (in the case of multiple parts in the same cfg) and parse each for details about the part
            if cfg.select{|line| line.match(/^PART/)}.first
              #incases of a maim mod dir having sub divisions within it    
              sub_mod_dir = folders[2] if folders[2] && folders[2].downcase != "parts" 
              part_info.merge!(:sub_mod => sub_mod_dir) if sub_mod_dir

              

              @part_scanner.get_part_modules(cfg, "PART").map do |sub_component| #this deals with the case of a cfg file containing multiple parts
                print "Parts Found: #{count += 1}\r".light_blue
                #collect certain variables from part and return part's name            
                begin
                  part = KerbalX::PartData.new({:part => sub_component, :identifier => mod_dir})
                  
                  unless part.name.nil?
                    part_info.merge!(:name => part.name, :attributes => part.attributes)
                    part_info.clone
                  end                 
                rescue => e
                  @logger.log_error "Failed to read part in #{cfg_path} - #{e}".red
                  nil
                end
              end
            end

          elsif cfg_path.match(/^Parts/)        
            part_info = {}
          else
            @ignored_cfgs << cfg_path
            part_info = {}
          end
        rescue Exception => e
          @logger.log_error "Error in index_parts while attempting to read part file\nFailed Part path: #{cfg_path}\n#{e}\n#{e.backtrace.first}".red
          @ignored_cfgs << cfg_path
          part_info = {}
        end
      end.flatten.compact

      print "Parts Found: #{count}".blue
      puts " done".green
     
      #Construct parts hash. ensuring that part info is not blank and that it has a name key    
      @parts = part_data.select{|part|  
        !part.empty? && part.has_key?(:name)
      }.map{|n| 
        {n[:name].gsub("_",".") => n} 
      }.inject{|i,j| i.merge(j)}   

    end

       
    #takes a hash of part info from the PartParser ie; {"part_name" => {hash_of_part_info}, ...}
    #and returns a hash of mod_name entails array of part names, {mod_name => ["part_name", "part_name"], ...}
    def grouped_parts parts = self.parts     
      grouped_parts = parts.group_by{|k,v| v[:mod]} #group parts by mod
      grouped_parts.map{|mod, group| 
        { mod => group.map{|g| g.first} }           #remove other part info, leaving just array of part names
      }.inject{|i,j| i.merge(j)}                    #re hash
    end

    def part_attributes mod_names = nil
      g_parts = self.grouped_parts
      parts_with_attributes = {}

      mod_names ||= g_parts.keys
      mod_names = [mod_names].flatten

      mod_names.each do |mod_name|
        g_parts[mod_name].each do |part_name|
          parts_with_attributes[part_name] = self.parts[part_name][:attributes]
        end
      end
    
      parts_with_attributes

    end

    #return part info for the given part name
    def locate part_name
      @parts[part_name]
    end

    #encode data as a json string (for writing to file)
    def to_json
      {
        :parts => @parts,
        :resources => @resources,
        :internals => @internals,
        :props => @props,
        :ignored_cfgs => @ignored_cfgs
      }.to_json
    end

    def show
      puts @parts.to_json
    end

=begin    
    #link resources, internals and props with parts
    def associate_components  
      #associate internals and resources with parts
      @parts.each do |name, data|
        data[:internals] = associate_component(data[:file], @internals)
        data[:resources] = associate_component(data[:file], @resources)
        data.delete(:file) #remove the raw file data as it's no longer needed and would waste space if written to file
      end
      #associate props with internals
      @internals.each do |name, data| 
        data[:props] = associate_component(data[:file], @props) 
        data.delete(:file)  #remove the raw file data
      end
    end

    #given the cfg_file of a part or internal and a group of sub comonents (internals, resources, props) 
    #it searches throu the cfg_file and finds references to the sub comonents
    def associate_component cfg_file, components
      components.select{|name, data|
        cfg_file.select{|l| !l.match("//") && l.include?("name") && l.include?("=") }.map{|l| l.match(/\s#{name}\s/)}.any?
      }.map{|name, data| name}
    end
=end

  end
end
