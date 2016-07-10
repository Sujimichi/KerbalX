require 'spec_helper'


describe KerbalX::CkanReader do 
  before :each do  
    @path = KerbalX.root(["test_env"])
    
  end

  describe "load config" do 
    before(:each) do 
      @conf_data = {"ksp_version"=>"1.1.2", "ignore_list"=>["ignore_1", "ignore_2"]}
      Dir.chdir(@path)
      FileUtils.rm("config.json") rescue false
      Dir.chdir(KerbalX.root)
    end
    it 'should load config options from file' do 
      @reader = KerbalX::CkanReader.new :dir => @path
      @reader.ignore_list.should == []
      @reader.config.should == {"ksp_version" => "1.0.0"}      
      File.open(KerbalX.root(["test_env", "config.json"]), "w"){|f| f.write( JSON.pretty_generate(@conf_data) ) }
      @reader.send(:load_config) 
      @reader.ignore_list.should == ["ignore_1", "ignore_2"]
      @reader.config["ksp_version"].should == "1.1.2"

    end
  end

end
