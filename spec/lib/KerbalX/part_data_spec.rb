require 'spec_helper'


describe KerbalX::PartData do 
  before :each do  
    @root = KerbalX.root(["test_env"])

  end

  describe "get_part_modules" do 
    before :each do 
      @part_data = KerbalX::PartData.new
      path_1 = File.join(@root, "GameData/Squad/Parts/FuelTank/fuelTank_long/part.cfg")
      path_2 = File.join(@root, "GameData/Squad/Parts/Engine/liquidEngineMini/part.cfg")
      path_3 = File.join(@root, "GameData/MagicSmokeIndustries/Parts/IR_HingeOpen/part.cfg")
      path_4 = File.join(@root, "GameData/NearFuturePropulsion/Parts/Engines/vasimr-25/vasimr-25.cfg")
    
    
      @single_part = File.open(path_1,"r:bom|utf-8"){|f| f.readlines}
      @engine_part = File.open(path_2,"r:bom|utf-8"){|f| f.readlines}
      @multi_part = File.open(path_3,"r:bom|utf-8"){|f| f.readlines}
      @odd_part = File.open(path_4,"r:bom|utf-8"){|f| f.readlines}
    end

    it "should return parts" do 
      @part_data.get_part_modules(@single_part, "PART").count.should == 1
      @part_data.get_part_modules(@engine_part, "PART").count.should == 1
      @part_data.get_part_modules(@multi_part, "PART").count.should == 3    
      @part_data.get_part_modules(@odd_part, "PART").count.should == 1
    end

    it "should return resources" do 
      @part_data.get_part_modules(@single_part, "RESOURCE").count.should == 2
    end

    it 'should return modules' do
      @part_data.get_part_modules(@engine_part, "MODULE").count.should == 4
      @part_data.get_part_modules(@single_part, "MODULE").count.should == 0
    end

    describe "nested modules" do 
      
      it 'should return all items from the part' do 
        @part_data.get_part_modules(@engine_part, "PROPELLANT").count.should == 2
      end

      it 'should return items from just within modules' do 
        @part_data.get_part_modules(@engine_part, "MODULE").map do |part_module| 
          @part_data.get_part_modules(part_module, "PROPELLANT").count
        end.should == [2,0,0,0]
      end

    end

  end

  describe "read_attributes_from" do 
    before :each do 
      @p = KerbalX::PartData.new
      path_1 = File.join(@root, "GameData/Squad/Parts/FuelTank/fuelTank_long/part.cfg")
      @file = File.open(path_1,"r:bom|utf-8"){|f| f.readlines}
    end

    it 'should return first matching given values for a given container' do 
      @p.read_attributes_from(@file, ["name"]).should == {"name" => "fuelTank_long"}
    end

    it 'should return multiple given values for the container' do 
      @p.get_part_modules(@file, "RESOURCE").map do |res|
        @p.read_attributes_from(@file, ["name", "amount", "maxAmount"])
      end.should == [{"name"=>"fuelTank_long", "amount"=>360, "maxAmount"=>360}, {"name"=>"fuelTank_long", "amount"=>360, "maxAmount"=>360}]
    end

    it 'should interpret strings as string, integers as integers and floats as floats' do 
      container = ["RESOURCE", "{", " name = LiquidFuel", " amount = 42.2", " maxAmount = 360", "}"]
      data = @p.read_attributes_from(container, ["name", "amount", "maxAmount"])
      data["name"].should be_a String
      data["amount"].should be_a Float
      data["maxAmount"].should be_a Integer
    end

    it 'should interpret numbers in scientific notation' do 
      container = ["RESOURCE", "{", " name = LiquidFuel", " amount = 1.005828E-02", " maxAmount = 38.5", "}"]
      data = @p.read_attributes_from(container, ["name", "amount", "maxAmount"])
      data["maxAmount"].should == 38.5
      data["amount"].should == 0.01005828
    end

    it 'should ignore missing attributes' do 
      container = ["RESOURCE", "{", " name = LiquidFuel", " maxAmount = 38.5", "}"]
      data = @p.read_attributes_from(container, ["name", "amount", "maxAmount"])
      data.keys.should == ["name", "maxAmount"]
      data["maxAmount"].should == 38.5      
    end

  end


  describe "assign_part_data_to_parts" do 
    before :each do 
      @part_data = KerbalX::PartData.new
    end

    it 'should associate parts (from server) with part data from the reader' do 
      server_parts = {"mod1" => ["part1", "part2", "part3", "part4"], "mod2" => ["part5", "part6", "part7"]}
      reader_parts = {"mod1" => {"part1" => "some_prt_data", "part2" => "foobar"}, "mod2" => {"part6" => "test"}}

      @part_data.assign_part_data_to_parts reader_parts, server_parts
      @part_data.parts.should == {"part1"=>"some_prt_data", "part2"=>"foobar", "part6"=>"test"}
    end

    it 'should make the association of a part to its data regardless of which mod it is in' do 
      #ideally parts and thier mods should line up, but the core rule of KerbalX is that parts are unique.  There will only be one part of a given
      #name on the server and after conflict resolution there will only be one part of a given name in the reader's part data.  It might be that 
      #conflict resolution will assign to part to a different mod to the one it has been voted into on the server.  Therefore containing mod is ignored 
      #in this assignment
      server_parts = {"mod1" => ["part1", "part2", "part3", "part4"], "mod2" => ["part5", "part6", "part7"]}
      reader_parts = {"mod1" => {"part1" => "some_prt_data", "part2" => "foobar", "part5" => "misplaced_part"}, "mod2" => {"part6" => "test"}}

      @part_data.assign_part_data_to_parts reader_parts, server_parts
      @part_data.parts.should == {"part1"=>"some_prt_data", "part2"=>"foobar", "part5" => "misplaced_part", "part6"=>"test"}

    end

  end
end
