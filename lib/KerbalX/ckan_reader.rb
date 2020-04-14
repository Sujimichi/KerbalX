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


#TODO
#- add list of mods to skip, ie; large mods that are known to not have parts (Astronomers packs)
#- add a clean up process that removes extracted cfg files from the GameData folder (possibly just nukes entire folder)
#  and removes downloaded zips (needs to be optional, but will be needed once this is running on KerbalX)

module KerbalX

  class InstallStanza

    def initialize(stanza)
      @file = stanza[:file]
      @find = stanza[:find]
      @find_regexp = stanza[:find_regexp]
      @filter = stanza[:filter]
      @filter_regexp = stanza[:filter_regexp]
    end

    def self.default(data)
      InstallStanza.new({:find => data[:identifier]})
    end

    def match?(path)
      if not @file.nil?
        path.start_with?(@file) and not filtered?(path)
      elsif not @find.nil?
        path.include?(@find) and not filtered?(path)
      elsif not @find_regexp.nil?
        path.match?(@find_regexp) and not filtered?(path)
      else
        false
      end
    end

    def filtered?(path)
      if not @filter.nil?
        if @filter.is_a?(Array)
          @filter.any? {|f| path.include?(f)}
        else
          path.include?(@filter)
        end
      elsif not @filter_regexp.nil?
        path.match?(@filter_regexp)
      else
        false
      end
    end

  end

  class InstallStanzas

    def initialize(data)
      @stanzas = data[:install].nil? ? [InstallStanza.default(data)] : data[:install].map {|stanza| InstallStanza.new(stanza)}
    end

    def match?(path)
      @stanzas.any? {|stanza| stanza.match?(path)}
    end

  end

  class CkanReader
    require 'json'
    require 'open-uri'
    require 'open_uri_redirections'
    require 'progressbar'
    require 'zip/zip'
    require 'digest'
    require "KerbalX/extensions" unless [].respond_to?(:split)

    attr_accessor :files, :data, :mod_data, :part_data, :errors, :activity_log, :message_log, :processed_mods, :mod_data_checksum, :resources
    attr_accessor :config, :perform_conflict_resolution, :pretty_json, :halt_on_error, :verbose, :silent
    

    def initialize args = {}
      defaults = {:dir => Dir.getwd, :activity_log => nil, :ckan_repo => "https://github.com/KSP-CKAN/CKAN-meta.git"}
      args = defaults.merge(args)
      @dir = args[:dir]                     #dir where reop will be cloned into and where zips will be downloaded to an unpacked
      @ckan_repo = args[:ckan_repo]         #address for the CKAN repo on github
      @repo = "CKAN-meta"                   #name of the CKAN repo's folder
      @part_scanner = KerbalX::PartData.new
      @mod_data = {}                        #store for resultant info of mods and their parts
      @part_data= {}                        #srore for part variable data
      @errors = []                          #store for tracking errors during run
      @message_log = []                     #log of running messages
      @verbose = false                      #if true then show extra warnings (ie when files in GameData are being replaced)
      @silent = false                       #if true then DONT show text output 
      @pretty_json = true                   #if true then format JSON with whitespace and newlines
      @halt_on_error = false
      @skip_removal = args[:skip_removal].to_s.eql?("true")
      @perform_conflict_resolution = true
      
      @mod_dir= "ModArchive"                #Folder were mod zips are downloaded into
      @site_interface = args[:interface]    #instance of KerbalX::Interface which has been initialized with an auth-token
      load_activity_log args[:activity_log] #prepare activity log (either initialize from given arg, or load from disk or create anew).
      @processed_mods = []
      @mod_data_checksum = nil
      @config = {}
      load_config                           #read in options including list of mods which will be excluded from processing
    end


    ##~~Fetch, Update and Read CKAN-meta repo~~##
    #methods to handle fetching and updating CKAN repo and
    #parsing it to produce @data, a hash of the required data

    #fetch the awesome CKAN-meta repo 
    def clone_repo
      return update_repo if Dir.exists?(File.join([@dir, @repo]))
      puts "Cloning CKAN-meta repo into #{@dir}"
      cur_dir = Dir.getwd
      Dir.chdir(@dir)
      `git clone #{@ckan_repo}`
      Dir.chdir(cur_dir)
    end

    #update CKAN-meta repo
    def update_repo
      return clone_repo unless Dir.exists?(File.join([@dir, @repo]))
      puts "Updating CKAN-meta repo in #{File.join([@dir, @repo])}"
      Dir.chdir(File.join([@dir, @repo]))
      `git pull origin master`
      Dir.chdir(@dir)
      @files = nil
      @data = nil
      return nil
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
          {:identifier => data["identifier"], :name => data["name"], :url => data["download"], :version => data["version"], :status => data["release_status"], :install => InstallStanzas.new(data)} #return required values
        rescue => e
          log_error [file, "ERROR: failed to find or parse file\n#{e}"]
          {} #in case of error return an empty hash
        end
      end.group_by{|ckan_data| ckan_data[:identifier]} #group the array into a hash indexed by the unique identifier value
      
      #inject ckan like data for Stock parts, requires that the stock (Squad) game data folder is present in accordingly named zip in the mod archive (ie Squad-1.1.2.zip) 
      @data["Squad"] = [{:identifier => "Squad", :name => "Squad", :url => "", :version => @config["ksp_version"], :status => nil}]       
      @data["MakingHistoryDLC"] =  [{:identifier => "MakingHistoryDLC",  :name => "Making History DLC",  :url => "", :version => @config["making_history_version"],  :status => nil}] if @config["making_history_version"]
      @data["BreakingGroundDLC"] = [{:identifier => "BreakingGroundDLC", :name => "Breaking Ground DLC", :url => "", :version => @config["breaking_ground_version"], :status => nil}] if @config["breaking_ground_version"]
      
      @data
    end

    alias read_ckan_info read_ckan_info_from



    ##~~Main Processing Methods~~##

    #Main Method - This is the primary entry point method. It ensures the CKAN-meta repo has been parsed and @data assembled
    #then itterates over a given subset of identifiers (all to_process if none given) and passes each one to process_identifier
    #which in turn downloads, unpacks and reads out part name info from the .cfg files.
    def process subset = to_process, args = {}
      all_mods(subset){|identifier, reader| reader.process_identifier(identifier, args) }
      resolve_conflicts if @perform_conflict_resolution #remove duplicate instances of parts, ensure each part belongs to just one mod.
      @mod_data.each do |mod,data|
        data[:part_data_checksum] = Digest::SHA256.hexdigest(@part_data[mod].to_json)
      end
      @processed_mods = subset
      return nil
    end

    #return array of identifiers that need to be processed
    #returns identifiers who's latest version is not tracked in the @activity_log
    def to_process
      all_mods{|id,r| r.latest_version_for(id)}.map{|m| [m[:identifier], m[:version]]      
      }.select{|id,v| not already_logged? id, v}.map{|id, v| id}
    end

    #for a given identifier, download the latest version zip, unpack the cfg files and read part names
    #returns a hash with data for the identifier {identifier => {:parts => part_name_Array, :name => String, :version => String}}
    def process_identifier identifier, args = {}
      args = {:force => false}.merge(args)
      data = latest_version_for identifier

      #stop process if the identifier and version have already been logged, unless :force => true is given in args
      return msg "#{data[:identifier]} #{data[:version]} has already been processed" if already_logged?(data[:identifier], data[:version]) && !args[:force]

      skip = false
      skip = "deprectaed" if data[:version].downcase.match(/deprecated/)
      skip = "non-stable-release" if data[:status] && !data[:status].downcase.eql?("stable")
      skip = "on ignore list" if ignore_list.include?(data[:identifier])

      if skip.eql?(false)

        #I love Ruby!! The identifier key is passed to downloaded (alias for download) which downloads the zip unless it's already present
        #either way download returns the identifier data and passes that to unpacked (alias for unpack) which extracts just the .cfg files
        #unpack returns an Array of paths to the cfg files which are passed to read_parts_from which scans them and returns an array of part names       
        @identifier = identifier #set identifier as @var so it's accessible in read_parts_from
        parts = read_parts_from unpacked downloaded identifier 
        
        #getting the most common root_dir is the best guess at the name PartMapper will have found for a mod and therefore what it will be called on KerbalX
        root_dir = @root_dirs.group_by{|i| i}.values.max_by(&:size) #@root_dirs is populated by read_parts_from with the root dir inside GameData for each cfg
        root_dir = root_dir.first if root_dir
        if root_dir.blank?
          msg "Assumption: root folder not found for #{identifier}, using identifier as root_dir".yellow
          root_dir = identifier
        end

        log_error "WARNING: a duplicate part somehow made it though to here!".red if parts.detect{|p| parts.count(p) > 1}
       
        #assemble hash of parts and other info for the identifier
        mod_info = {
          :name => data[:name], 
          :root_folder => root_dir, 
          :version => data[:version], 
          :url => data[:url], 
          :part_data_checksum => nil,
          :parts => (parts || [])          
        }
        mod_info[:resources] = @resources unless @resources.blank?
        @mod_data.merge!(identifier => mod_info) #unless parts.empty? #merge the info about the identifier with @mod_data UNLESS it has no parts

        main_string = "Complete; #{parts.size} part names discovered in #{data[:identifier]} #{data[:version]}".blue
        r_string = "\nFound #{@resources.count} resources".green unless @resources.blank?
        msg "#{main_string}#{r_string}\n\n"

      else
        msg "Skipped #{data[:identifier]}; #{skip}\n".yellow
      end
      log_activity identifier, {data[:version] => {:processed_on => Time.now}} unless skip.eql?("on ignore list")

      data
    end

    #takes a block to be performed for all mods, passes -identifier and self into the block
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
          log_error "FAILED ON: #{indentifier}: #{e}".red
          remove_downloads_for indentifier, :just => data[:version]
          msg "\n"
        end
      end.compact
    end



    ##~~Mod Data Handlers~~##
    #methods to handled fetching and unpacking a mod
    #and extracting part name info from it


    #Get the latest data (name, version, download_url) for a given identifier
    def latest_version_for identifier
      read_ckan_info_from unless @data  #ensure @data is present
      if identifier == "Squad"
        mod = [{:identifier => "Squad", :name => "Squad", :url => "", :version => @config["ksp_version"], :status => nil}]
      else
        mod = @data[identifier]           #select array of info for given identifier    
      end
      return log_error "#{identifier} was not found in ckan data" unless mod    
      #sort by version and return last element. see comments on sortable_version method for sort process.
      mod.sort_by_version{|m| m[:version] }.last
    end

    
    #takes a hash with the keys :url, :identifier and :version and downloads the zip from the url and stores it accorder to :identifier and :version 
    #OR when given a string (an identifier) will lookup the latest version from CKAN-meta data and then download and store that.
    def download identifier_hash
      data = identifier_hash_for identifier_hash #returns latest version identifier_hash if given ckan_identifier or just returns if given an identifier_hash
      mod_archive = File.join([@dir, @mod_dir]) 
      zip_path = File.join([mod_archive, "#{data[:identifier]}-#{data[:version]}.zip"]) 

      Dir.mkdir(mod_archive) unless Dir.entries(@dir).include? @mod_dir #create dir for downloading zips into 

      if File.exists?(zip_path) && !File.zero?(zip_path) #don't download if zip is already present
        msg "#{data[:identifier]}-#{data[:version]}.zip already downloaded".light_blue
      else
        #download url and store as a zip named according to indentifier
        host = URI.parse(data[:url]).host
        msg "Downloading #{data[:identifier]} version: #{data[:version]}\nfrom: #{host}"
        if host.eql?("kerbalstuff.com")
          log_error "Skipping...KerbalStuff.com no longer exists".red
          raise "missing host #{host}"
        end
        
        pbar = nil
        open_uri_options = progress_bar(pbar)
        open_uri_options.merge!(:allow_redirections => :all) if host.eql?("spacedock.info")
        open(zip_path, 'wb'){|file| file.print open(data[:url], open_uri_options).read  }
        msg "\n"
        if File.zero?(zip_path)
          File.delete(zip_path)
          log_error "download of #{data[:url]} failed, zip was 0 bytes".red
        end
      end
      remove_downloads_for data, :keep => data[:version]
      return identifier_hash
    end
    alias downloaded download


    #removes downloaded zips for a given mod (take identifier or identifier_hash). 
    #pass in {:just => <version or array of versions>} to remove specific zips
    #pass in {:keep => <version or array of versions>} to remove all but versions specified
    def remove_downloads_for identifier_hash, args = {}
      data = identifier_hash_for identifier_hash #returns latest version identifier_hash if given ckan_identifier or just returns if given an identifier_hash
      args[:keep] ||= [] #ensure :keep is not nil
      args[:keep] = [args[:keep]].flatten #ensure keep is an array.
      mod_archive = File.join([@dir, @mod_dir]) 
            
      #set previous_versions to either what was passed in as args[:just] OR all versions except those in args[:keep]
      previous_versions = args[:just] ? [args[:just]] : @data[data[:identifier]].map{|i| i[:version]} - args[:keep]

      #for the versions in previous_versions create file paths for the files that are present.
      to_remove = previous_versions.map do |previous_version|
        File.join([mod_archive, "#{data[:identifier]}-#{previous_version}.zip"]) 
      end.select{|path| File.exists?(path) }      

      #remote the files
      begin
        unless to_remove.empty?
          if @skip_removal
            msg "SKIPPING REMOVAL".red
            return false
          end
          
          msg "Removing unneeded downloads:".light_blue
          to_remove.each do |old_path|
            msg "\tremoving #{old_path.sub(mod_archive, "")}".light_blue
            File.delete(old_path)
          end
        end
      rescue
        log_error "ERROR deleting downloads for #{data[:identifier]}".red
      end
    end


    #takes a hash with :identifier and :version keys or an identifier string (in which case the latest version is used. 
    #opens a corresponding zip (which should have been downloaded by self.download) and unpacks just the .cfg files into a GameData folder in @dir
    #returns an array of paths to the unpacked cfg files to be used in read_parts_from
    def unpack identifier_hash
      data = identifier_hash_for identifier_hash #returns latest version identifier_hash if given ckan_identifier or just returns if given an identifier_hash
      zip_name = "#{data[:identifier]}-#{data[:version]}.zip"
      install = data[:install]
      msg "Unpacking #{zip_name}"
      unpacked_cfg_paths = []
      Zip::ZipFile.open(File.join([@dir, @mod_dir, zip_name])) do |zip|
        zip.each do |entry|
          if entry && entry.name.match(/.cfg$/) && install.match?(entry.name)
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
      @root_dirs = []
      @resources = {}
      @identifier ||= "no_identifier"
      cfg_paths.map do |cfg_path|
        next if cfg_path.include?("__MACOSX") #skip __MACOSX files
        begin
          cfg = File.open(cfg_path,"r:bom|utf-8"){|f| f.readlines} #open the cfg file using Unicode BOM to deal with some encoding present in cfg files.          
        rescue
          log_error "failed to read #{cfg_path.sub(@dir, "")}".red
          next #skip this file 
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
          log_error "no significant line found in: #{cfg_path.sub(@dir, "")}".yellow 
          next
        end

        #if a cfg contains definitions of resources extra info about the resources.
        if cfg.select{|line| line.match(/^RESOURCE_DEFINITION/)}.first
          @part_scanner.get_part_modules(cfg, "RESOURCE_DEFINITION").map do |resource|            
            resource_attrs = @part_scanner.read_attributes_from resource, ["name", "density", "unitCost", "volume"]
            resource_name = resource_attrs["name"]
            resource_attrs.delete("name")            
            @resources[resource_name] = resource_attrs
          end
        end

        
        
        #if cfg contains PART then split it on instances of PART (in the case of multiple parts in the same cfg) and parse each for details about the part
        if cfg.select{|line| line.match(/^PART/)}.first
          #find the root folder inside GameData that the cfg is in (this will be the name that KerbalX knows the mod as, due to the way the PartMapper tool works)
          @root_dirs << cfg_path.split("GameData/").last.split("/").first 
          @part_scanner.get_part_modules(cfg, "PART").map do |sub_component| #this deals with the case of a cfg file containing multiple parts
            #collect certain variables from part and return part's name            
            begin
              part = KerbalX::PartData.new({:part => sub_component, :identifier => @identifier, :logger => self})
              unless (part.name.nil? || part.attributes.empty?)
                @part_data[@identifier] ||= {}
                @part_data[@identifier][part.name] = part.attributes
              end
              part.name #part name is returned as the product of the .map loop
            rescue => e
              log_error "Failed to read part in #{cfg_path} - #{e}".red
              nil
            end
          end
        end

      end.flatten.compact.uniq
    end



    #Resolve situation where a part is found to be present in more than one mod.
    #The first method used is to fetch info from KerbalX about known parts and which mods they belong to on the site
    #That is then used to make the choice of which mod to add the part to.
    #If the part is not known about on the site then unfortunatly the best that I can come up with here is to simply assign
    #it to the first mod in the list.
    def resolve_conflicts
      msg "\nChecking for conflicting parts...."
      return msg "@mod_data unchanged since last run, skipping conflict resolution" if @mod_data_checksum.eql?(Digest::SHA256.hexdigest(@mod_data.to_json))
      conflict_map = conflicting_parts
      return msg "No conflicts to resolve" if conflict_map.empty?

      msg "There are #{conflict_map.keys.size} conflicting parts to resolve"
      msg "fetching part info from #{@site_interface.remote_address}"
      kx_part_info = @site_interface.lookup_part_info conflict_map.keys
      log_error "Failed to fetch data from #{@site_interface.site}".red if kx_part_info.keys == ["error"]
      msg "processing conflicting parts"

      conflict_map.each do |part, conflicting_mods|     
        winning_mod = nil
        part_info = kx_part_info[part]

        guess = true
        if !part_info.nil? && part_info.keys.include?("mod")
          mod_on_kx = part_info["mod"]["ckan_identifier"] || part_info["mod"]["name"]
          winning_mod = conflicting_mods.select{|m| m.downcase.eql?(mod_on_kx.downcase)}.first
          guess = false unless winning_mod.nil?
        end
        winning_mod ||= conflicting_mods.first

        conflicting_mods.delete(winning_mod)
        msg "#{guess ? "[BY GUESS]".red : "[INFORMED]".blue} Resolving #{part}; assigning it to #{winning_mod}, removing it from #{conflicting_mods.join(", ")}"
        conflicting_mods.each{|mod| 
          @mod_data[mod][:parts].delete(part) #remove duplicate part from conflicting mod
          @part_data[mod].delete(part) if @part_data[mod] #remote duplicate part (if it exists) from conflicting mod in part data
        }
      end
      @mod_data_checksum = Digest::SHA256.hexdigest(@mod_data.to_json)
      return nil
    end


    #return array of mod names from config.json which are to be ignored, or return empty array of none defined
    def ignore_list
      @config["ignore_list"] || []
    end


    #Helper method, not used in main logic, just for doing a quick lookup of available versions for given identifier
    def versions_for identifier
      read_ckan_info_from unless @data
      @data[identifier].sort_by_version{|m| m[:version] }.map{|v| v[:version]}
    end

    #takes either a ckan_identifier (ie "B9") or an identifier_hash.  If identifier_hash is given it is simply returned
    #if ckan_identifier is given it will return the identifier_hash for the lastest version of that mod
    def identifier_hash_for identifier_hash
      identifier_hash.is_a?(String) ? latest_version_for(identifier_hash) : identifier_hash #select latest version from given identifier or use given identifier_hash
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

    def reset
      @mod_data = {}
      @part_data = {}
      @activity_log = {}
      @errors = []
      @message_log = []
      @mod_data_checksum = nil
    end

    #find out if any parts exist in more than one mod.
    #returns a hash of {partname => [array_of_mods_that_contain_that_part]}
    def conflicting_parts
      all_parts = @mod_data.map{|k,v| v[:parts]}.flatten.uniq
      conflict_map = all_parts.map do |p|
        {p => @mod_data.select{|k,v| v[:parts].include?(p)}.map{|k,v| k} }
      end.select{|d| d.values.flatten.size > 1}.inject{|i,j| i.merge(j)}
      conflict_map || {} #return empty hash if there are no conficts
    end

    def show_conflicts
      conflict_map = conflicting_parts
      return puts "There are no conflicts" if conflict_map.empty?
      puts conflict_map.map{|k,v| "#{k} => #{v}"}
    end

    def compaire mod, args = {}
      moda = mod
      modb = args[:with]
      a_minus_b = @mod_data[moda][:parts] - @mod_data[modb][:parts]
      b_minus_a = @mod_data[modb][:parts] - @mod_data[moda][:parts]

      if a_minus_b.empty? && b_minus_a.empty?
        puts "both contain the same parts"
      else
        if b_minus_a.empty? && !a_minus_b.empty?
          puts "#{moda} contains all the parts from #{modb} and has #{a_minus_b.size} more parts"
          puts a_minus_b.inspect
        end
        if a_minus_b.empty? && !b_minus_a.empty?
          puts "#{modb} contains all the parts from #{moda} and has #{b_minus_a.size} more parts"
          puts b_minus_a.inspect
        end
        if !a_minus_b.empty? && !b_minus_a.empty?
          shared = @mod_data[moda][:parts] - (a_minus_b)
          puts "#{modb} shares #{shared.size} pars with #{moda}"
          puts shared.inspect      
        end
      end
    end

    def json_data opt = :mod_data
      if opt.to_s.downcase.include?("mod")
        make_json(@mod_data)
      elsif opt.to_s.downcase.include?("part")
        make_json(@part_data)
      end
    end

    #write mod and part data to json files 
    def save_data
      save_json_file "mod_data", @mod_data
      save_json_file "part_data", @part_data
    end

    #load mod and part data from files and set in @ variables with a poor-man's HashWithIndifferentAccess
    def load_data file_prefix = nil      
      load_indifferent_access_hash_from_json_file "mod_data", file_prefix
      load_indifferent_access_hash_from_json_file "part_data", file_prefix
    end
    
        
    #list of mods to ignore, these are mods that are known to not contain any parts, or if they do contain parts they conflict with or completely include other mods
    def load_config
      @config = JSON.parse(File.open(File.join([@dir, "config.json"]), 'r'){|f| f.readlines}.join) rescue {"ksp_version" => "1.0.0"}
    end

   
    #Add entry to @activity_log and save the log's json string to file
    def log_activity identifier, data
      @activity_log[identifier] ||= {}
      @activity_log[identifier].merge!(data)
      File.open(File.join([@dir, "activity.log"]), "w"){|f| f.write make_json(@activity_log) }      
    end

    #passes a string to puts unless @silent is true
    #all output should use this rather than using puts directly
    #so text output can be silenced
    def msg string
      @message_log << string
      puts string unless @silent
    end
        
    #Record an error and if @verbose is true print to screen as they occur
    def log_error error
      raise error.inspect if @halt_on_error
      msg [error].flatten.join("\n") unless @silent
      @errors << error
      return nil
    end

    def show_errors types = :all
      cols = %w[red green yellow blue pink light_blue]
      errs = @errors
      types = types.to_s
      unless types.eql?("all")
        codes = types.split(" ").map{|type| "\e[#{cols.index(type) + 31}m" }
        errs = errs.select{|e| codes.map{|c| e.include?(c)}.any? }      
      end      
      errs.each{|err| puts "#{err}\n"}
      return nil
    end


    private


    def save_json_file file_name, data
      File.open(File.join([@dir,"#{file_name}.json"]), "w"){|f| f.write make_json(data) }
    end

    def load_indifferent_access_hash_from_json_file file_name, file_prefix = nil
      begin
        data = JSON.parse(File.open(File.join([@dir,"#{file_prefix}#{file_name}.json"]), "r"){|f| f.readlines }.join)
      rescue
        msg "No #{file_prefix}#{file_name} file to load"
      end
      if data
        default_proc = proc do |h, k|
          case k
          when String then sym = k.to_sym; h[sym] if h.key?(sym)
          when Symbol then str = k.to_s; h[str] if h.key?(str)
          end
        end 
        data = data.map{|k,v| v.default_proc = default_proc; {k => v}}.inject{|i,j| i.merge(j)}
        data.default_proc = default_proc
        instance_variable_set("@#{file_name}", data)
        instance_variable_set("@#{file_name}_checksum", Digest::SHA256.hexdigest(data.to_json))
      end
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


    #returns a JSON strong for the given object
    #if @pretty_json is set to true then it's formatted for human readability
    #otherwise it's compact
    def make_json object
      if @pretty_json
        JSON.pretty_generate(object)
      else
        object.to_json
      end
    end

  end

end
