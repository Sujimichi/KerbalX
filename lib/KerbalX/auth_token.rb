module KerbalX

  class AuthToken
    attr_accessor :errors

    def initialize dir
      @errors = []
      begin
        path = File.join([dir, "KerbalX.key"])
        kX_key = File.open(path, "r"){|f| f.readlines}.join.chomp.lstrip
      rescue
        kX_key = ""
        @errors << "Could not read your KerbalX token. \nMake sure your KerbalX.key is in #{dir}"
      end

      @email = kX_key.split(":").first
      @token = kX_key.split(":").last

    end

    def valid?
      return false if @email.blank? || @token.blank?
      true
    end

    def to_hash
      raise "I'm sorry Dave, I'm afraid I can't do that; #{@errors.join(", ")}" unless valid?
      {:token => @token, :email => @email}
    end

  end

end
