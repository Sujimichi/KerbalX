require 'spec_helper'

describe KerbalX::Interface do 
  before(:all) do       
    @path = File.join(File.dirname(__FILE__), "..", "test_env")
    @file_path = File.join(File.dirname(__FILE__), "..", "test_env", "KerbalX.key")
    @token  = KerbalX::AuthToken.new(@path)
  end

  it 'should work like this' do 
   
    KerbalX::Interface.new(@token) do |kerbalx|
      kerbalx.update_knowledge_base_with  KerbalX::PartParser.new(@path).parts
    end

  end


  describe "group_parts_by_mod" do 
    before(:each) do  
      @interface = KerbalX::Interface.new(@token)
      @parts = {
        "this_part" => {:mod => "mod1", :other_data => "stuff"},
        "that_part" => {:mod => "mod2", :other_data => "stuff"},
        "some_part" => {:mod => "mod1", :other_data => "stuff"},
        "kerb_part" => {:mod => "mod3", :other_data => "stuff"},
        "bendy_part"=> {:mod => "mod2", :other_data => "stuff"}
      }
 
    end 
 
    it 'should group the parts by mod' do
      parts_by_mod = @interface.group_parts_by_mod @parts  
      parts_by_mod.keys.sort.should == ["mod1", "mod2", "mod3"]
    end

    it 'should have an array of part names for each mod' do 
      parts_by_mod = @interface.group_parts_by_mod @parts  
      parts_by_mod["mod1"].should == ["this_part", "some_part"]
      parts_by_mod["mod2"].should == ["that_part", "bendy_part"]
      parts_by_mod["mod3"].should == ["kerb_part"]
    end

  end  

end
