module KerbalX

  class PartData
    attr_accessor :name, :attributes, :parts, :not_found

    PartVariables = ["cost", "mass", "category", "CrewCapacity", "TechRequired"] 

    def initialize args = {}
      @logger = args[:logger]
      if args[:part] && args[:identifier]
        @identifier = args[:identifier]
        @name = nil
        @attributes = {}
        self.read_part_variables args[:part]
      elsif args[:reader] && args[:parts_without_data]
        self.assign_part_data_to_parts args[:reader].part_data, args[:parts_without_data]
      end
    end

    def assign_part_data_to_parts part_data, parts_without_data
      #lookup_map = part_data.keys.map{|k| {k.downcase.gsub(" ","").gsub("_","") => k} }.reduce(Hash.new, :merge)
      msg "Looking for data for #{parts_without_data.map{|k,v| v}.flatten.count} parts...".blue
      @parts = {} 
      @not_found = []

      part_map = part_data.map{|mod, parts| parts}.reduce(Hash.new, :merge)

      parts_without_data.each do |mod_name, parts|
        parts.each do |part|
          data = part_map[part]
          if data #&& !data.empty?
            @parts[part] = data
          else
            @not_found << part
          end
        end
        print "Found data for #{@parts.keys.count} parts, #{@not_found.count} parts not found\r".blue
      end
      msg "Found data for #{@parts.keys.count} parts, #{@not_found.count} parts not found".blue
    end


    #read variables and part_name from part 
    def read_part_variables part
      part_name = part.select{|line| line.include?("name =")}.first #find the first instance of attribute "name" and return value
      part_name = part_name.sub("name = ","").strip.sub("@",'').chomp unless part_name.blank? #remove preceeding and trailing chars - gsub("\t","").gsub(" ","") replaced with strip
      return nil if part_name.blank?

      @name = part_name.gsub("_",".") #part names need to be as they appear in craft files, '_' is used in the cfg but is replaced with '.' in craft files     
      @attributes = {}

      #fix for cases of "invalid byte sequence in UTF-8" error. Some cases need converting to UTF-16 and back to UTF-8 to cure the issue.
      part = part.utf_safe
      part = part.select{|line| !line.blank?}

      @attributes.merge!(read_attributes_from(part, PartData::PartVariables))

      part_string = part.map{|line| line.strip}.join("\n")
      if part_string.include?("ModuleEngines") 
        engine_modules = get_part_modules(part, "MODULE").select{|m| m.join.include?("ModuleEngines") }.reverse 
        #the reverse is so that the first instance of enigne info is processed last, so if there are module manager entries that change the engine performance, 
        #they are essentially ignored and just the stock values are kept.


        engine_modules.each do |engine_module|
          engine_id = engine_module.select{|l| l.match(/^engineID = /) }.first || "standard"
          engine_id.sub!("engineID = ", "")
          engine_data = {"isp" => {}, "propellant_ratios" => {}}

          #read ISP data - currently ignoring ISP data for jet engines
          if engine_module.join.include?("velCurve") || engine_module.join.include?("atmCurve")       
            engine_data["isp"] = nil
          else
            begin
              atmo_curve = get_part_modules(engine_module, "atmosphereCurve").first        
              next if atmo_curve.nil?
              engine_data["isp"][:vac] = atmo_curve.select{|l| l.strip.match(/^key = 0/) }.first.strip.sub("key = 0 ", "").to_f #intentionall will throw error if no vac isp is found
              atmo_isp= atmo_curve.select{|l| l.strip.match(/^key = 1/) }.first #atmo isp may not be present for all engines
              engine_data["isp"][:atmo]= atmo_isp.strip.sub("key = 1 ", "").to_f if atmo_isp
            rescue => e
              log_error "failed to read ISP data for #{@identifier}, #{@name}".yellow
            end
          end        

          #read propellant requirements for engine mode
          props = get_part_modules(engine_module, "PROPELLANT")
          begin
            props.each do |prop|
              name = prop.select{|l| l.strip.match(/^name/)}.first
              ratio= prop.select{|l| l.strip.match(/^ratio/)}.first
              name = name.strip.sub("name = ", "") if name
              ratio= ratio.strip.sub("ratio = ", "").to_f if ratio
              if name && ratio
                engine_data["propellant_ratios"][name] = ratio
              end              
            end
          rescue => e
            log_error "failed to read Propellant data for #{@identifier}, #{@name}".yellow
          end

          #read thrust data
          begin
            thrust = engine_module.select{|l| l.strip.match(/^maxThrust/)}.first.strip.sub("maxThrust = ", "")
            engine_data["max_thrust"] = thrust.to_f
          rescue
            log_error "failed to read Thrust data for #{@identifier} - #{@name}".yellow
          end

          @attributes["engine_data"] ||= {}
          @attributes["engine_data"][engine_id] = engine_data

        end  
      end


      resources = get_part_modules(part, "RESOURCE").select{|r| r.join.include?("maxAmount")}
      unless resources.empty?
        @attributes["resources"] = {}
        resources.each do |resource|
          name = resource.select{|l| l.match(/^name/) }.first
          name = name.sub("name = ","") if name
          max_amount = resource.select{|l| l.match(/^maxAmount/) }.first
          max_amount = max_amount.sub("maxAmount = ","").to_f if max_amount

          @attributes["resources"][name] = max_amount
        end
      end
    end


    def get_part_modules part, module_name
      brackets = 0
      in_scope = false
      regexp = /\b(#{module_name})\b/

      sel = part.select{|line| 
        next if line.blank?
        if line.match(regexp)
          in_scope = true
          brackets = line.include?("{") ? 1 : 0
          true
        else
          if in_scope            
            brackets += 1 if line.include?("{")
            brackets -= 1 if line.include?("}")          
            in_scope = false if brackets <= 0
          end
          brackets >= 1
        end  
      }

      sel = sel.join("\n").split(regexp).select{|l| !l.match(regexp) && !l.blank? }
      sel.map{|m| 
        m.strip.split("\n").map{|line| line.strip.sub("@","").split("//").first }.select{|g| !g.blank?} 
      }.select{|g| !g.blank?}
    end

    def read_attributes_from part, attributes
      matched_attributes = {}

      attributes.each do |var|
        val = part.select{|line| !line.strip.match("^//") && line.include?("#{var} =") }.first 
        begin
          val = val.sub("#{var} =","").split("//").first.strip.sub("@",'').chomp unless val.blank? #remove preceeding and trailing chars - gsub("\t","").gsub(" ","") replaced with strip         
        rescue
          val = ""
        end

        if val && val.to_i.to_s.eql?(val)
          val = val.to_i 
        else
          val = ("%.#{val.split(".").last.length}f" % val ).to_f rescue val #attempt to coerse into float if possible ie "0.4" or "1.005828E-02" otherwise return the original string
        end
        matched_attributes[var] = val unless val.nil?        
      end
      matched_attributes
    end


    def log_error error
      if @logger
        @logger.log_error error
      else
        raise error
      end      
    end

    def msg string
      if @logger && @logger.respond_to?(:msg)
        @logger.msg string
      else
        puts string
      end
    end

  end

end
