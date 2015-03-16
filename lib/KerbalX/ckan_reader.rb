
#INITIAL SETUP
# clone CKAN-meta repo 

#PROCESS
# read all .ckan files and group them by the ckan identifier value (unique value, identifier == mod)
# for each identifier (mod) 
#   identify latest version 
#   download zip for latest version
#   unpack just the .cfg files
#   parse .cfg files to identify which contain parts (using logic from original KX part_mapper)
#   assemble data for itentifier;
#     {identifier => {:name => "human name string", :parts => [array of part names], :version => "version string" } }



#It may be the case that two mods (or a mod and an extension to that mod) might contain the same part files
#Need to identify when that happens and think of a way to handle that situation

#Two ways to approach this. 
#1) download all mods and uppack, then parse the whole unpacked dir in one go
#2) download and parse the data for each mod 1 at a time. <---Will probably do this, and the unpack process will return 
#   which files it unpacked and then just those will be parsed by the part mapper

#TODO
#- add list of mods to skip, ie; large mods that are known to not have parts (Astronomers packs)
#- add a clean up process that removes extracted cfg files from the GameData folder (possibly just nukes entire folder)
#  and removes downloaded zips (needs to be optional, but will be needed once this is running on KerbalX)

=begin
load 'CkanMetaReader.rb'
reader = CkanMetaReader.new
reader.read_ckan_info

=end

class CkanReader
  require 'json'
  require 'open-uri'
  require 'progressbar'
  require 'zip'
  #require "KerbalX/extensions"
  
  attr_accessor :files, :data, :mod_data, :errors, :activity_log, :verbose, :silent, :pretty_json

  def initialize args = {}
    defaults = {:dir => Dir.getwd, :activity_log => nil}
    args = defaults.merge(args)
    @dir = args[:dir]     #dir where reop will be cloned into and where zips will be downloaded to an unpacked
    @repo = "CKAN-meta"   #name of the CKAN repo's folder
    @mod_data = {}        #store for resultant info of mods and their parts
    @errors = []          #store for tracking errors during run
    @verbose = true       #if true then show extra warnings (ie when files in GameData are being replaced)
    @silent = false       #if true then DONT show text output 
    @pretty_json = true   #if true then format JSON with whitespace and newlines
    
    load_activity_log args[:activity_log] #prepare activity log (either initialize from given arg, or load from disk or create anew.
  end


  ##~~Fetch, Update and Read CKAN-meta repo~~##
  #methods to handle fetching and updating CKAN repo and
  #parsing it to produce @data, a hash of the required data

  #fetch the awesome CKAN-meta repo 
  #TODO block this is repo already exists
  def clone_repo
    cur_dir = Dir.getwd
    Dir.chdir(@dir)
    `git clone https://github.com/KSP-CKAN/CKAN-meta.git`
    Dir.chdir(cur_dir)
  end

  #update CKAN-meta repo
  #TODO call clone_repo if repo does not exist
  def update_repo
    Dir.chdir(File.join([@dir, @repo]))
    `git pull origin master`
    Dir.chdir(@dir)
  end

  #find all the .ckan files in the CKAN-meta repo
  def find_ckan_files
    @files = Dir.glob(File.join([@dir, "CKAN-meta/**/*/*.ckan"]))
  end

  #Read the .ckan files in the CKAN-meta repo and extract required info
  #results in a hash of {identifier => [{:identifier => "identifier", :name => "human_name", :url => "url string", :version => "version string"}, ...other_versions...]}
  def read_ckan_info_from files = @files  #can be passed an array of files, if none given then those present in @files are used  
    files = find_ckan_files if files.nil? #if files has not been populated call find_ckan_files to return array of .ckan file locations
    @data = files.map do |file|
      begin
        data = JSON.parse(File.open(file, "r"){|f| f.readlines}.join("\n")) #Read file and parse contents with JSON
        {:identifier => data["identifier"], :name => data["name"], :url => data["download"], :version => data["version"]} #return required values
      rescue => e
        log_error [file, "ERROR: failed to find or parse file\n#{e}"]
        {} #in case of error return an empty hash
      end
    end.group_by{|ckan_data| ckan_data[:identifier]} #group the array into a hash indexed by the unique identifier value
  end
  alias read_ckan_info read_ckan_info_from



  ##~~Main Processing Methods~~##

  #for a given identifier, download the latest version zip, unpack the cfg files and read part names
  #returns a hash with data for the identifier {identifier => {:parts => part_name_Array, :name => String, :version => String}}
  def process_identifier identifier
    data = latest_version_for identifier

    #stop process if the identifier and version have already been logged.
    return msg "#{data[:identifier]} #{data[:version]} has already been processed" if already_logged? data[:identifier], data[:version]

    #I love Ruby!! The identifier key is passed to downloaded (alias for download) which downloads the zip unless it's already present
    #either way download returns the identifier data and passes that to unpacked (alias for unpack) which extracts just the .cfg files
    #unpack returns an Array of paths to the cfg files which are passed to read_parts_from which scans them and returns an array of part names 
    parts = read_parts_from unpacked downloaded identifier
    log_activity identifier, {data[:version] => {:processed_on => Time.now}}

    msg "Complete; #{parts.size} part names discovered in #{data[:identifier]} #{data[:version]}\n\n"

    #assemble hash of parts and other info for the identifier
    data = {identifier => {:name => data[:name], :version => data[:version], :parts => parts}}
    @mod_data.merge!(data)
    data
  end

  #takes a block to be performed for all mods, passes identifier and self into the block
  #For Example, print all available versions 
  # reader.all_mods{|id, r| msg "#{id} - #{r.versions_for(id)}" }
  #can also be given a subset of identifiers to work on rather than entire set of mods
  def all_mods subset = nil, &blk
    read_ckan_info_from unless @data  #ensure @data is present
    subset ||= @data.keys.sort_by{|i| i.downcase} #if subset is not provided, set it to be all identifier keys
    subset.map do |indentifier|
      begin
        yield(indentifier, self)
      rescue => e
        log_error "FAILED ON: #{indentifier}\n#{e}"
        nil
      end
    end.compact
  end

  def process subset = []
    #subset = ["SCANsat", "Kethane", "BahamutoDynamicsPartsPack", "B9", "InfernalRobotics", "RemoteTech"]
    #subset = to_process
    all_mods(subset) do |identifier, reader|
      reader.process_identifier(identifier)
    end
    return nil
  end


  ##~~Helper Methods~~##

  #Get the latest data (name, version, download_url) for a given identifier
  def latest_version_for identifier
    read_ckan_info_from unless @data  #ensure @data is present
    mod = @data[identifier]           #select array of info for given identifier    
    return log_error "#{identifier} was not found in ckan data" unless mod    
    #sort by version and return last element. see comments on sortable_version method for sort process.
    mod.sort_by{|m| sortable_version m[:version] }.last
  end

  #Helper method, not used in main logic, just for doing a quick lookup of available versions for given identifier
  def versions_for identifier
    read_ckan_info_from unless @data
    @data[identifier].sort_by{|m| sortable_version m[:version] }.map{|v| v[:version]}
  end

  #simple lookup for partial identifier, returns any identifier keys that contain the given value
  def find mod_name
    read_ckan_info_from unless @data
    @data.keys.select{|k| k.downcase.include?(mod_name.downcase)}
  end

  #check if given identifier is present and if it has an entry for given version
  def already_logged? identifier, version
    @activity_log.has_key?(identifier) && @activity_log[identifier].has_key?(version)
  end

  #return array of identifiers that need to be processed
  def to_process
    all_mods{|m,r| r.latest_version_for(m)}.map{|m| 
      [m[:identifier], m[:version]]
    }.select{|id,v| not already_logged? id, v}.map{|id, v| id}
  end

  #write @mod_data to disk as json string
  def save_mod_data
    File.open(File.join([@dir,"mod_data.json"]), "w"){|f| f.write make_json(@mod_data) }      
  end


  ##~~Mod Data Handlers~~##
  #methods to handled fetching and unpacking a mod
  #and extracting part name info from it

  #takes a hash with the keys :url, :identifier and :version and downloads the zip from the url and stores it accorder to :identifier and :version 
  #OR when given a string (an identifier) will lookup the latest version from CKAN-meta data and then download and store that.
  def download identifier_hash
    data = identifier_hash.is_a?(String) ? latest_version_for(identifier_hash) : identifier_hash #select latest version from given identifier or use given identifier_hash
    temp_dir = File.join([@dir, "temp"]) 
    zip_path = File.join([temp_dir, "#{data[:identifier]}-#{data[:version]}.zip"]) 

    Dir.mkdir(temp_dir) unless Dir.entries(@dir).include? "temp" #create temp dir for downloading zips into 

    if File.exists?(zip_path) #don't download if zip is already present
      msg "#{data[:identifier]}-#{data[:version]}.zip already downloaded"
      return identifier_hash
    else
      #download url and store as a zip named according to indentifier
      msg "Downloading #{data[:identifier]} version: #{data[:version]}"
      pbar = nil
      open(zip_path, 'wb'){|file| file.print open(data[:url], progress_bar(pbar)).read  }
      msg "\n"
      return identifier_hash
    end
  end
  alias downloaded download

  #takes a hash with :identifier and :version keys or an identifier string (in which case the latest version is used. 
  #opens a corresponding zip (which should have been downloaded by self.download) and unpacks just the .cfg files into a GameData folder in @dir
  #returns an array of paths to the unpacked cfg files to be used in read_parts_from
  def unpack identifier_hash
    data = identifier_hash.is_a?(String) ? latest_version_for(identifier_hash) : identifier_hash #select latest version from given identifier or use given identifier_hash
    zip_name = "#{data[:identifier]}-#{data[:version]}.zip"
    msg "Unpacking #{zip_name}"
    unpacked_cfg_paths = []
    Zip::File.open(File.join([@dir, "temp", zip_name])) do |zip| 
      zip.each do |entry| 
        if entry.name.match(/.cfg$/)
          path = entry.name
          path = File.join(["GameData", path]) unless path.match(/^GameData/)        
          path = File.join([@dir, path])
          unpacked_cfg_paths << path
          FileUtils.mkpath File.dirname(path)
          if File.exists?(path)
            File.delete(path)
            log_error "WARNING; replacing file - '#{path}'" if @verbose
          end
          entry.extract(path)
        end
      end
    end
    unpacked_cfg_paths #return array of paths to the unpacked .cfg files
  end
  alias unpacked unpack #this alias is just to make for a nicer sentence ie read_parts_from unpacked identifier


  #given an array of paths to cfg files, returns an array of partnames
  #read each cfg and determine if it contains PART info and return the names of the parts found
  #based on the logic from KerbalX::PartParser so has some concepts that may now be legacy (ie multiple parts in single .cfg file)
  def read_parts_from cfg_paths
    cfg_paths.map do |cfg_path|
      cfg = File.open(cfg_path,"r:bom|utf-8"){|f| f.readlines} #open the cfg file using Unicode BOM to deal with some encoding present in cfg files.
      first_significant_line = cfg.select{|line| line.match("//").nil? && !line.chomp.empty? }.first #find first line that isn't comments or empty space
      if first_significant_line.match(/^PART/)        
        cfg.split(first_significant_line).map do |sub_component| #this deals with the case of a cfg file containing multiple parts
          name = sub_component.select{|line| line.include?("name =")}.first #find the first instance of attribute "name" and return value
          name = name.sub("name = ","").strip.sub("@",'').chomp unless name.blank? #remove preceeding and trailing chars - gsub("\t","").gsub(" ","") replaced with strip
          name.gsub("_",".") #part names need to be as they appear in craft files, '_' is used in the cfg but is replaced with '.' in craft files
        end
      end
    end.flatten.compact
  end



  private

  #returns an Array of the component parts of a version number such that it can be enumerated
  #Example use:
  # ["8.1", "v10.0", "v8.1", "v8.0"].sort_by{|i| sortable_version(i)} => ["8.1", "v8.0", "v8.1", "v10.0"]
  # ["R5.2.8", "R5.2.6", "R5.2.7"  ].sort_by{|i| sortable_version(i)} => ["R5.2.6", "R5.2.7", "R5.2.8"]
  # ["0.1", "0.1.2-fixed", "0.1.2" ].sort_by{|i| sortable_version(i)} => ["0.1", "0.1.2", "0.1.2-fixed"] 
  def sortable_version version_number 
    version_number.split(".").map{|component|   #split the version number by '.' -> version components
      component.split(/(\d+)/).map{|s|          #split each version component into alphas and numerics ie "v10" -> ["v", "10"] or "5-pre" -> ["5", "-pre"]
        (!!Float(s) rescue false) ? s.to_i : s  #convert strings that contain numerical values into Floats, otherwise remain as strings
      }
    }
  end


  #confguration for the download progress bar. If silent is true
  #then the prog-bar won't be shown.
  def progress_bar pbar    
    {
      :content_length_proc => lambda { |t|
        return if @silent
        if t && 0 < t
          pbar = ProgressBar.new("downloading", t)
          pbar.bar_mark = "="
          pbar.file_transfer_mode
        end
      },
      :progress_proc => lambda {|s| 
        return if @silent
        pbar.set s if pbar
      }
    }
  end


  #either load activity_log file from disk, initialize it from a given JSON string or 
  #initialize it as an empty hash
  def load_activity_log alternative_log = nil
    log_path = File.join([@dir, "activity.log"])
    if alternative_log #if given a JSON string then initialize the log from that
      @activity_log = JSON.parse(alternative_log) rescue nil
    elsif File.exists?(log_path) #otherwise load it from file
      @activity_log = JSON.parse(File.open(log_path, "r"){|f| f.readlines}.join) rescue nil
    end
    @activity_log ||= {} #if log is still nil, then set it as empty hash
  end
  
  #Add entry to @activity_log and save the log's json string to file
  def log_activity identifier, data
    @activity_log[identifier] ||= {}
    @activity_log[identifier].merge!(data)
    File.open(File.join([@dir, "activity.log"]), "w"){|f| f.write make_json(@activity_log) }      
  end



  #Record an error and if @verbose is true print to screen as they occur
  def log_error error
    msg [error].flatten.join("\n") unless @silent
    @errors << error
    return nil
  end

  #passes a string to puts unless @silent is true
  #all output should use this rather than using puts directly
  #so text output can be silenced
  def msg string
    puts string unless @silent
  end

  def make_json object
    if @pretty_json
      JSON.pretty_generate(object)
    else
      object.to_json
    end
  end

end
