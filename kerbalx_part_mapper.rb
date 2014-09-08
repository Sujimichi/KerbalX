#!/usr/bin/env ruby
##PartMapper
#PartMapper is a component of KerbalX.com 
#It's function is to scan a local KSP GameData folder and then 
#transmit a list of which parts where found in which mods to KerbalX


#PartParser is a class taken from Jebretary which is a rails project.
#In order to leave PartParser unchanged from how it is in Jebretary
#and for it to work in a pure ruby environment some additional additional 
#classes and methods are needed to make up for the ones rails provides.

class HashWithIndifferentAccess < Hash
end

class Array
  def split n = []
    a =self.dup
    b = []
    while a.include?(n)
      b << a[0..a.index(n)-1]
      a =  a[a.index(n)+1..a.size]
    end
    b << a
    b
  end

  def blank?
    self.nil? || self.empty?
  end
end

class String
  def blank?
    self.nil? || self.empty?
  end
end

class NilClass
  def blank?
    true
  end
end


#Class imported from Jebretary
#Reads all .cfg files and determines the names of the parts inside
class PartParser

  class LegacyPartException  < StandardError; end 
  class UnknownPartException < StandardError; end


  require 'json'
  attr_accessor :parts, :resources, :internals, :props, :ignored_cfgs

  def initialize dir, args = {:source => :game_folder, :write_to_file => false}
    begin
      @stock_parts = System.new.get_config["stock_parts"]
      raise "@stock_parts is not an array" unless @stock_parts.is_a?(Array)
      raise "@stock_parts contains non string elements" unless @stock_parts.map{|i| i.is_a?(String)}.all?
    rescue Exception => e
      #System.log_error "Could not read custom stock part definition\n#{@stock_parts.inspect}\n#{e}\n#{e.backtrace.first}"
      @stock_parts = ["Squad", "NASAmission"]
    end

    @instance_dir = dir
    #args[:source] = :game_folder if Rails.env.eql?("development")
    if args[:source] == :game_folder
      cur_dir = Dir.getwd
      Dir.chdir(@instance_dir)
      begin
        index_parts
        @parts ||= {}
        associate_components  
        write_to_file if args[:write_to_file] #unless Rails.env.eql?("development")
      rescue Exception => e
        #System.log_error "Failed to build map of installed parts\n#{e}\n#{e.backtrace.first}"
      end      
      Dir.chdir(cur_dir)
    else
      read_from_file 
    end
  end

  def read_from_file
    data = File.open(File.join([@instance_dir, "jebretary.partsDB"]),'r'){|f| f.readlines.join }
    parts_from_file = HashWithIndifferentAccess.new(JSON.parse(data))
    @parts = parts_from_file[:parts]
    @resources = parts_from_file[:resources]
    @internals = parts_from_file[:internals]
    @props = parts_from_file[:props]
    @ignored_cfgs = parts_from_file[:ignored_cfgs]
  end

  def write_to_file
    File.open(File.join([@instance_dir, "jebretary.partsDB"]),'w'){|f| f.write self.to_json}
  end

  def discover_cfgs
    Dir.glob("**/*/*.cfg")      #find all the .cfg files
  end

  def index_parts 
    part_cfgs = discover_cfgs
    @resources = {}
    @internals = {}
    @props = {}
    @ignored_cfgs = []
    part_info = part_cfgs.map do |cfg_path|
      @alert = false
      cfg = File.open(cfg_path,"r:ASCII-8BIT"){|f| f.readlines}
      begin
        next if cfg_path.include?("mechjeb_settings") #not all .cfg files are part files, some are settings, this ignores mechjeb settings (which are numerous). 

        #next if cfg_path.match(/GameData\/\w+.cfg/) #ignore cfg files in the root of GameData
        next if cfg_path.match(/^GameData\//) && cfg_path.split("/").size.eql?(2)
        next if cfg_path.match(/^saves\//) #ignore cfg files in saves folder

        #Others will be ignored by the next line failing to run
        part_name = cfg.select{|line| line.include?("name =")}.first.sub("name = ","").sub("@","").gsub("\t","").gsub(" ","").chomp
        print "."
        @alert = true if part_name.include?("pod")
      rescue Exception => e
        @ignored_cfgs << cfg_path
        #System.log_error "Error in index_parts while attempting to read part name\nFailed Part path: #{cfg_path}\n#{e}"
        next
      end

      begin
        dir = cfg_path.sub("/part.cfg","")
        part_info = {:dir => dir, :path => cfg_path }


        if cfg_path.match(/^GameData/)
          folders = dir.split("/")
          mod_dir = folders[1] #mod dir is the directory inside GameData

          part_info.merge!(:mod => mod_dir)
          part_info.merge!(:stock => true) if @stock_parts.include?(mod_dir)

          #determine the type of cfg file
          first_significant_line = cfg.select{|line| line.match("//").nil? && !line.chomp.empty? }.first #first line that isn't comments or empty space
          type = :part     if first_significant_line.match(/^PART/)
          type = :prop     if first_significant_line.match(/^PROP/)
          type = :internal if first_significant_line.match(/^INTERNAL/)
          type = :resource if first_significant_line.match(/^RESOURCE_DEFINITION/)
          type ||= :part #assume undetected headings will be parts
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
        #System.log_error "Error in index_parts while attempting to read part file\nFailed Part path: #{cfg_path}\n#{e}\n#{e.backtrace.first}"
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

  def associate_components
    #associate internals and resources with parts
    @parts.each do |name, data|
      data[:internals] = associate_component(data[:file], @internals)
      data[:resources] = associate_component(data[:file], @resources)
      data.delete(:file)
    end
    #associate props with internals
    @internals.each do |name, data| 
      data[:props] = associate_component(data[:file], @props) 
      data.delete(:file)
    end
  end

  #given the cfg_file of a part or internal and a group of sub comonents (internals, resources, props) 
  #it searches throu the cfg_file and finds references to the sub comonents
  def associate_component cfg_file, components
    components.select{|name, data|
      cfg_file.select{|l| !l.match("//") && l.include?("name") && l.include?("=") }.map{|l| l.match(/\s#{name}\s/)}.any?
    }.map{|name, data| name}
  end

  def locate part_name
    @parts[part_name]
  end

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


#replacement for the logging class from Jebretary
class PartParser::System
  def self.log_error args
  end
end


#Boiler plate to manage running PartParser and reading the users auth-key
#in order to transmit the data to KerbalX
class KerbalXPartMapper
  require 'net/http'

  def self.run path = Dir.getwd
    ok_to_run = true
    #path = "/home/sujimichi/KSP/KSPv0.23.0-Mod"
    #path = "/home/sujimichi/KSP/KSPv0.24-Stock"
    begin
      kX_key = File.open("KerbalX.key", "r"){|f| f.readlines}.first.chomp.lstrip
      raise "It must be a string" unless kX_key.is_a?(String)
      raise "It must not be empty" if kX_key.empty?
    rescue => e
      ok_to_run = false
      puts "Unable to read your KerbalX token. #{e}\nMake sure you place the token in a file called KerbalX.key in your KSP folder next to this exe."
      kX_key = nil
    end
    unless Dir.entries(path).include?("GameData") 
      ok_to_run = false
      puts "\n\nCould not see your GameData folder.  Run me from the root KSP folder\n\n"
    end

    if ok_to_run
      email = kX_key.split(":").first
      token = kX_key.split(":").last

      parser = KerbalXPartMapper.new(path, email, token)
      parser.parse
      parser.transmit
    end
    sleep(10)
  end

  def initialize path, email, token
    @path = path
    @target = "http://kerbalx.com/knowledge_base/update"
    #@target = "http://localhost:3000/knowledge_base/update"
    @token = token
    @email = email
  end

  def parse
    #parse parts using the Jebretary PartParser, its a bit overkill as it returns interals etc, 
    puts "\n\nScanning your installed parts\n"
    parts = PartParser.new(@path, :source => :game_folder, :write_to_file => false)
    @parts = parts.parts 

    #return parts grouped by mod, {mod_name => [<part_info>, <part_info>,...] }  
    mod_groups = @parts.group_by{|k,v| v[:mod]}

    #return hash of mods to array of part names, {mod_name => ["part_name", "part_name"] }
    @data = mod_groups.map { |grp| {grp[0] => grp[1].map{|part| part[0]} } }.inject{|i,j| i.merge(j)}
  end

  def transmit    
    @data ||= {}
    if @data.empty?
      puts "Did not find any parts, sorry"
    else
      puts "\n\n#{@data.keys.size} Mods and #{@data.values.flatten.size} Parts detected in your KSP install:\n#{@path}"
      sleep 1
      puts "\nTransmitting Data to #{@target}"
      responses = []
      @data.each do |k,v| 
        print "\nsending info about '#{k}'..."
        begin
          r = send_data @target, {:part_data => {k => v}.to_json, :token => @token, :email => @email}        
          sleep(2)
          responses << r
          if r.code == "200"
            puts "OK"
            begin
              puts JSON.parse(r.body)["message"] 
            rescue
            end          
          else
            puts "\n\ttransmission failed #{r.code}"
          end
        rescue 
          puts "\n\ttransmission failed"
        end
      end

      puts JSON.parse(responses.last.body)["closing_message"] 
      if responses.empty? || responses.map{|r| !r.code.to_s.eql?("200")}.any?
        puts "!!Some requests failed to run!!"
        responses.select{|r| !r.code.to_s.eql?("200")}.map{|r| r.message }.uniq.each do |message|
          puts "\t#{message}"
        end
      end
    
    end
  end

  def send_data url, data = {}
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(data)
    response = http.request(request)
  end


end
KerbalXPartMapper.run
