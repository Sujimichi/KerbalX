require 'spec_helper'

describe KerbalX::AuthToken do 
  before(:all) do       
    @path = File.join(File.dirname(__FILE__), "..", "test_env")
    @file_path = File.join(File.dirname(__FILE__), "..", "test_env", "KerbalX.key")
    @original_token_file = File.open(@file_path, "r"){|f| f.readlines}.join
  end
  after(:each) do 
    File.open(@file_path, "w"){|f| f.write @original_token_file }
  end

  describe "reading the KerbalX.key file" do 

    it 'should read a KerbalX.key file in the given dir and assign @token and @email' do 
      File.open(@file_path, "w"){|f| f.write "foo@goo.com:some_horriffic_string_of_stuff" }

      token = KerbalX::AuthToken.new(@path)
      token.instance_variable_get("@token").should == "some_horriffic_string_of_stuff"
      token.instance_variable_get("@email").should == "foo@goo.com"
    end

    describe "when missing the file" do 
      before(:each) do 
        File.delete(@file_path)
        @token = KerbalX::AuthToken.new(@path)
      end
      
      it 'should cope with the file not being present' do                
        @token.instance_variable_get("@token").should be_blank
        @token.instance_variable_get("@email").should be_blank
      end  

      it 'should not be valid if the token or email are blank' do 
        @token.should_not be_valid 
      end

      it 'should have errors which report why it is invalid' do 
        @token.errors.join.should be_include "Could not read your KerbalX token" 
      end

    end

  end


  describe "params for transmission" do 
    before(:each)  do 
      File.open(@file_path, "w"){|f| f.write "foo@goo.com:some_horriffic_string_of_stuff" }      
    end
 
    it 'should return a hash of the email and token params' do       
      @token = KerbalX::AuthToken.new(@path)
      @token.to_hash.should == {:email => "foo@goo.com", :token => "some_horriffic_string_of_stuff"}
    end

    it 'should raise an error if called when it is invalid' do 
      File.delete(@file_path)
      @token = KerbalX::AuthToken.new(@path)

      error_raised = false
      begin
        @token.to_hash
      rescue
        error_raised = true
      end
      error_raised.should == true
    end

  end


end

