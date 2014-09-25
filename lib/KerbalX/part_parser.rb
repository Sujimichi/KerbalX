module PartParser
  attr_accessor :parts, :resources, :internals, :props, :ignored_cfgs, :logger
  
  class LegacyPartException  < StandardError; end 
  class UnknownPartException < StandardError; end

  require 'json'
  
  def initialize dir, args = {}
    defaults = {
      :source => :game_folder,                  #default is to read part info from the GameData folder. Alternative is to read from file.
      :write_to_file => false,                  #if set to true the data will be written to .partDB file (default is partmapper.parts.DB or name can be supplied by :file)
      :file => "part_mapper.partsDB",           #default name of file for writing to / reading from
      :stock_parts => ["Squad", "NASAmission"], #defines the default definition of which "mods" are stock
      :logger => KerbalX::Logger                #default logger, replace with a logger from the environment PartParser is being used it.
      #:ignore_mods => [mod_dir names to be skipped] optional
    }
    args = defaults.merge(args)
    
    @args         = args
    @logger       = args[:logger]
    @stock_parts  = args[:stock_parts]
    @instance_dir = dir

    if args[:source] == :game_folder
      cur_dir = Dir.getwd                     #note the current dir so it can be returned to after running
      Dir.chdir(@instance_dir)                #change into given dir
      begin
        index_parts                           #discover all .cfg files and determine what they defines (Parts, Resources, Props..etc)
        @parts ||= {}                         
        associate_components                  #associate props, internals and resources with parts
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
    @internals = {}
    @props = {}
    @ignored_cfgs = []
    part_info = part_cfgs.map do |cfg_path|

      #read .cfg file as ASCII-8BIT. read in this format to support some of the chars present in (some) KSP files.
      cfg = File.open(cfg_path,"r:ASCII-8BIT"){|f| f.readlines}

      begin
        next if cfg_path.include?("mechjeb_settings") #not all .cfg files are part files, some are settings, this ignores mechjeb settings (which are numerous). 
        next if cfg_path.match(/^GameData\//) && cfg_path.split("/").size.eql?(2) #ignore cfg files in the root of GameData
        next if cfg_path.match(/^saves\//) #ignore cfg files in saves folder

        #Others will be ignored by the next line failing to run
        part_name = cfg.select{|line| line.include?("name =")}.first.sub("name = ","").sub("@","").gsub("\t","").gsub(" ","").chomp
        print "."

      rescue Exception => e
        @ignored_cfgs << cfg_path
        #@logger.log_error "Error in index_parts while attempting to read part name\nFailed Part path: #{cfg_path}\n#{e.backtrace.first}"
        next
      end

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

          #determine if the cfg file defines a part, prop, internal or resouce.  
          #Other types (of which there are severl) don't need to be considered
          first_significant_line = cfg.select{|line| line.match("//").nil? && !line.chomp.empty? }.first #first line that isn't comments or empty space
          type = :part     if first_significant_line.match(/^PART/)
          type = :prop     if first_significant_line.match(/^PROP/)
          type = :internal if first_significant_line.match(/^INTERNAL/)
          type = :resource if first_significant_line.match(/^RESOURCE_DEFINITION/)
          type ||= :other

          part_info.merge!(:type => type)

          #incases of a maim mod dir having sub divisions within it    
          sub_mod_dir = folders[2] if type.eql?(:part) && folders[2].downcase != "parts" 
          part_info.merge!(:sub_mod => sub_mod_dir) if sub_mod_dir

          #subcompnents deals with when a .cfg includes info for more than one part or resouce etc.
          cfg.split( first_significant_line ).map do |sub_component|

            next if sub_component.blank?
            name = sub_component.select{|line| line.include?("name =")}.first
            next if name.blank?
            name = name.sub("name = ","").gsub("\t","").gsub(" ","").sub("@",'').chomp         
            part_info.merge!(:name => name)

            if type.eql?(:resource)            
              @resources.merge!(name => part_info.clone)
              nil
            elsif type.eql?(:internal)
              part_info.merge!(:file => cfg)
              @internals.merge!(name => part_info.clone)
              nil
            elsif type.eql?(:prop)
              @props.merge!(name => part_info.clone)
              nil
            elsif type.eql?(:other)
              @ignored_cfgs << cfg_path
              nil
            else #its a part init'
              part_info.merge!(:file => cfg)
              part_info.clone #return part info in the .map loop
            end            
          end.compact

        elsif cfg_path.match(/^Parts/)
          part_info.merge!(:name => part_name, :legacy => true, :type => :part, :mod => :unknown_legacy)
          part_info
        else
          @ignored_cfgs << cfg_path
          #raise UnknownPartException, "part #{cfg_path} is not in either GameData or the legacy Parts folder"
          #this could be a problem for people with legacy internals, props or resources
          part_info = {}
        end

      rescue Exception => e
        @logger.log_error "Error in index_parts while attempting to read part file\nFailed Part path: #{cfg_path}\n#{e}\n#{e.backtrace.first}"
        @ignored_cfgs << cfg_path
        part_info = {}
      end

    end.flatten.compact

    #Construct parts hash. ensuring that part info is not blank and that it has a name key    
    @parts = part_info.select{|part|  
      !part.empty? && part.has_key?(:name)
    }.map{|n| 
      {n[:name].gsub("_",".") => n} 
    }.inject{|i,j| i.merge(j)}   
  end

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

end
