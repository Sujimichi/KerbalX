#!/usr/bin/env ruby
##PartMapper
#PartMapper is a component of KerbalX.com 
#It's function is to scan a local KSP GameData folder and then 
#transmit a list of which parts where found in which mods to KerbalX



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
