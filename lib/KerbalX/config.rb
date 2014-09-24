module Config

  def self.log_error args
    puts "OMG, so..this happend\n"
    puts args
  end

  def initialize
    @config = {
      "stock_parts" => ["Squad", "NASAmission"]
    }
  end

  def get_config
    @config
  end

end
