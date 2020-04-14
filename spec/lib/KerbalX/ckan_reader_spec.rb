require 'spec_helper'


describe KerbalX::InstallStanzas do
  it 'file should match only installed files' do
    install = KerbalX::InstallStanzas.new({
      :install => [{
        :file => "GameData/TestModule"
      }]
    })
    expect(install.match?("GameData/TestModule")).to be true
    expect(install.match?("GameData/TestModule/my_patch.cfg")).to be true
    expect(install.match?("GameData/TestModule/Parts/my_part.cfg")).to be true
    expect(install.match?("install_instructions.txt")).to be false
    expect(install.match?("TestModule/bad_path_patch.cfg")).to be false
    expect(install.match?("GameData/BundledModule/Parts/weird_part.cfg")).to be false
  end
  it 'find should match installed files' do
    install = KerbalX::InstallStanzas.new({
      :install => [{
        :find => "TestModule"
      }]
    })
    expect(install.match?("TestModule")).to be true
    expect(install.match?("TestModule/my_patch.cfg")).to be true
    expect(install.match?("TestModule/Parts/my_part.cfg")).to be true
    expect(install.match?("BundledModule/Parts/another_part.cfg")).to be false
  end
  it 'find_regexp should match only installed files' do
    install = KerbalX::InstallStanzas.new({
      :install => [{
        :find_regexp => "CoolModule-[0-9.]+"
      }]
    })
    expect(install.match?("CoolModule-1.2.3.4/test_file.txt")).to be true
    expect(install.match?("CoolModule-asdf/test_file.txt")).to be false
    expect(install.match?("DumbModule-3.4.5/test_file.txt")).to be false
  end
  it 'default stanza should install only identifier-named folder' do
    install = KerbalX::InstallStanzas.new({
      :identifier => "MyModule"
    })
    expect(install.match?("MyModule/test_patch.cfg")).to be true
    expect(install.match?("GameData/MyModule/test_patch.cfg")).to be true
    expect(install.match?("GameData/MyModule/Parts/new_part.cfg")).to be true
    expect(install.match?("BundledModule/part.cfg")).to be false
  end
  it 'should not match filtered files' do
    install = KerbalX::InstallStanzas.new({
      :install => [{
        :find => "FilteredModule",
        :filter => [ "bad_file.cfg" ]
      }]
    })
    expect(install.match?("FilteredModule/good_file.cfg")).to be true
    expect(install.match?("FilteredModule/bad_file.cfg")).to be false
    expect(install.match?("FilteredModule/Parts/bad_file.cfg")).to be false
  end
end

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
