module KerbalX

  class PartData
    attr_accessor :name, :attributes

    PartVariables = ["cost", "mass", "category", "CrewCapacity", "TechRequired"] 

    def initialize args = {}
      if args[:part] && args[:identifier]
        @identifier = args[:identifier]
        @name = nil
        @attributes = {}
        self.read_part_variables args[:part]
      elsif args[:reader] && args[:parts_without_data]
        self.assign_part_data_to_parts args[:reader].part_data, args[:parts_without_data]
      end
    end

    def assign_part_data_to_parts part_data, parts
      lookup_map = part_data.keys.map{|k| {k.downcase.gsub(" ","").gsub("_","") => k} }.reduce(Hash.new, :merge)
      return lookup_map
    end

    #read variables and part_name from part 
    def read_part_variables part
      part_name = part.select{|line| line.include?("name =")}.first #find the first instance of attribute "name" and return value
      part_name = part_name.sub("name = ","").strip.sub("@",'').chomp unless part_name.blank? #remove preceeding and trailing chars - gsub("\t","").gsub(" ","") replaced with strip
      return nil if part_name.blank?

      @name = part_name.gsub("_",".") #part names need to be as they appear in craft files, '_' is used in the cfg but is replaced with '.' in craft files
      
      #@part_data[@identifier] ||= {}
      @attributes = {}

      PartData::PartVariables.each do |var|
        val = part.select{|line| !line.strip.match("^//") && line.include?("#{var} =")}.first 
        val = val.sub("#{var} = ","").split("//").first.strip.sub("@",'').chomp unless val.blank? #remove preceeding and trailing chars - gsub("\t","").gsub(" ","") replaced with strip
        if val && val.to_i.to_s.eql?(val)
          val = val.to_i 
        elsif val && "%.#{val.split(".").last.length}f" % val.to_f == val
          val = val.to_f
        end
        @attributes[var] = val unless val.nil?
      end

      part_string = part.map{|line| line.strip}.join("\n")
      if part_string.include?("ModuleEngines") 
        engine_modules = get_part_modules(part, "MODULE").select{|m| m.join.include?("ModuleEngines") }.reverse #the reverse is so that the first instance of enigne info is processed last, so if there are module manager entries that change the engine performance, they are essentially ignored and just the stock values are kept.

        #raise engine_modules.inspect if @name == "RAPIER"


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
              engine_data["isp"][:vac] = atmo_curve.select{|l| l.strip.match(/^key = 0/) }.first.strip.sub("key = 0 ", "").to_f #intentionall will throw error if no vac isp is found
              atmo_isp= atmo_curve.select{|l| l.strip.match(/^key = 1/) }.first #atmo isp may not be present for all engines
              engine_data["isp"][:atmo]= atmo_isp.strip.sub("key = 1 ", "").to_f if atmo_isp
            rescue => e
              log_error "failed to read ISP data for #{@identifier} - #{@name}\n#{e}\n#{atmo_curve}\n".red
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
            log_error "failed to read Propellant data for #{@identifier} - #{@name}\n#{e}\n#{props}\n".red
          end

          #read thrust data
          begin
            thrust = engine_module.select{|l| l.strip.match(/^maxThrust/)}.first.strip.sub("maxThrust = ", "")
            engine_data["max_thrust"] = thrust.to_f
          rescue
            log_error "failed to read Thrust data for #{@identifier} - #{@name}".red
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

      sel = part.select{|line| 
        if line.include?(module_name)
          in_scope = true
          brackets = 0
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
      sel.join("\n").split("#{module_name}").map{|l| l.strip.split("\n").map{|i|i.strip.sub("@","").sub("//","")}.select{|g| !g.blank?} }.select{|g| !g.blank?}
    end
    

  end

end
