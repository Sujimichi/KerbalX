module KerbalX

  class Interface
    require 'net/http'
    attr_accessor :site
    alias remote_address site 

    class FailedResponse
      attr_accessor :body, :code
      def initialize args
        @body = args[:body]
        @code = args[:code]
      end
    end

    def initialize site_url, token, &blk
      @site = site_url

      @token = token
      if @token.valid?
        yield(self) if block_given?
      else
        puts "\nUnable to proceed"
        puts @token.errors
      end
    end

    def update_knowledge_base_with parts
      mods_with_parts = group_parts_by_mod parts
      mods_with_parts ||= {}

      url = "#{@site}/knowledge_base/update"           
      responses = []

      @skip = false
      mods_with_parts.each do |mod_name, parts| 
        next if @skip
        print "\nsending info about '#{mod_name}'..."
        responses << transmit(url, :part_data => {mod_name => parts}.to_json)
      end

      show_summary responses
    end
      
    def update_knowledge_base_with_ckan_data ckan_data, log = {}
      url = "#{@site}/knowledge_base/update"           
      print "\nsending CKAN data to #{@site}..."
      response = transmit(url, :ckan_data => ckan_data, :log => log)
      puts response.body
    end

    def transmit url, data
      begin
        r = send_data url, data
        sleep(1)
      rescue => e
        r = FailedResponse.new :body => {:message => "Internal Error\n#{e}\n\n"}.to_json, :code => 500
      end
      puts r.code.to_s.eql?("200") ? "OK" : "Failed -> error: #{r.code}"
      cautiously { puts JSON.parse(r.body)["message"]  }
      if ["401", "426"].include?(r.code.to_s)
        puts "\nABORT!!"
        @skip = true 
      end             
      return r
    end

    def show_summary responses
      cautiously { puts JSON.parse(responses.last.body)["closing_message"] }
      failures = responses.select{|r| !r.code.to_s.eql?("200")}.map{|r| r.message }.uniq
      unless failures.blank?
        puts "Some requests could not be processed because reasons;"
        failures.each do |message|
          puts "\t#{message}"
        end
      end
    end

    
    #takes a hash of part info from the PartParser ie; {"part_name" => {hash_of_part_info}, ...}
    #and returns a hash of mod_name entails array of part names, {mod_name => ["part_name", "part_name"], ...}
    def group_parts_by_mod parts     
      grouped_parts = parts.group_by{|k,v| v[:mod]} #group parts by mod
      grouped_parts.map{|mod, group| 
        { mod => group.map{|g| g.first} }           #remove other part info, leaving just array of part names
      }.inject{|i,j| i.merge(j)}                    #re hash
    end

    def lookup_part_info part_names
      begin
        r = fetch("#{@site}/part_lookup.json", {:part_names => part_names.to_json}).body
        info = JSON.parse(r)
      rescue
        info = {"error" => "failed to get info from #{@site}"}
      end
      return info
    end


    private

    def send_data url, data = {}
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      http.read_timeout = 10000
      http.use_ssl = true if uri.scheme.eql?("https")
      data.merge! @token.to_hash
      data.merge! :version => KerbalX::VERSION

      request.set_form_data(data)
      response = http.request(request)
    end

    def cautiously &blk
      begin
        yield
      rescue => e
      end
    end

    def fetch url, data = {}
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme.eql?("https")
      request = Net::HTTP::Get.new(uri.request_uri)
      request.set_form_data(data)
      response = http.request(request)
    end       

  end 

end
