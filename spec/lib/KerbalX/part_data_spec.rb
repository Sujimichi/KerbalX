require 'spec_helper'


describe KerbalX::PartData do 
  before :each do  
    @root = KerbalX.root(["test_env"])
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

  describe "get_part_modules" do 
    before :each do 

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
end
