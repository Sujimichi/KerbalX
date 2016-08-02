require 'spec_helper'

describe KerbalX::PartParser do 

  before(:all) do 
    @path = File.join(File.dirname(__FILE__), "..", "..", "..", "test_env")
    @parser = KerbalX::PartParser.new @path
  end

  it 'it should find the correct number of parts' do 
    #should be 28 parts
    #The complexity of this test is more in the setup of the test_env folder which contains a number of 
    #different .cfg files defining parts and other aspects (resources, settings, all kinda stuff)
    #There are also some part.cfgs that define multiple parts as well as the more common 1 part per cfg setup
    #includes Modules which modify parts (ie from TweakScale) which have in the past been falsely identifyed as parts
    #contains Agency definitions. 
    @parser.parts.keys.count.should == 29
  end 

  it "should find known problem parts" do 
    @parser.parts.keys.should be_include "GooExperiment" #has utf BOM (\xEF\xBB\xBF) while most other parts do not.
  end
  
  it 'should have the correct mod folder for discovered parts' do 
    @parser.parts["JetEngine"][:mod].should == "Squad"
    @parser.parts["Size3AdvancedEngine"][:mod].should == "NASAmission"
    @parser.parts["IRPistonHalf"][:mod].should == "MagicSmokeIndustries"
    @parser.parts["B9.Control.RCS.Block.R6"][:mod].should == "B9_Aerospace"      
  end

  it 'should have resouces associated with the parts' do 
    @parser.parts["JetEngine"][:resources].should == ["LiquidFuel", "ElectricCharge", "IntakeAir"]
    @parser.parts["IRPistonHalf"][:resources].should be_empty
  end

  it 'should have internals associated with the parts' do 
    @parser.parts["mk1pod"][:internals].should == ["mk1PodCockpit"]
    @parser.parts["sepMotor1"][:internals].should be_empty
  end
 
  it 'should set :stock => true on parts from standard stock parts' do     
    @parser.parts["JetEngine"][:stock].should == true
    @parser.parts["Size3AdvancedEngine"][:stock].should == true
    @parser.parts["IRPistonHalf"][:stock].should == false
    @parser.parts["B9.Cockpit.MK2"][:stock].should == false
  end

  describe "with alternatve definition of stock parts" do 
    before(:all) do 
     @parser = KerbalX::PartParser.new @path, :stock_parts => ["Squad", "B9_Aerospace"]
    end

    it "should set stock => true on parts from given 'stock_parts' definition" do      
      @parser.parts["JetEngine"][:stock].should == true  
      @parser.parts["Size3AdvancedEngine"][:stock].should == false
      @parser.parts["B9.Cockpit.MK2"][:stock].should == true
    end

  end

  describe "resouces" do 

    it 'should have discovered resoucres' do 
      @parser.resources.keys.should == [
        "LiquidFuel", 
        "Oxidizer", 
        "SolidFuel", 
        "MonoPropellant", 
        "XenonGas", 
        "ElectricCharge", 
        "IntakeAir", 
        "EVAPropellant", 
        "B9CompressedAir"
      ] 
    end

  end

  describe "props" do 
    it 'should have discovered props' do 
      @parser.props.keys.should == ["NavBall", "B9_AbortButton", "B9_AbortButton2"]
    end
  end

  describe "internals" do 
    it 'should have discovered internals' do 
      @parser.internals.keys.should == ["mk1PodCockpit", "PodCockpit", "B9_Cockpit_HL_Internal"]
    end

    it 'should associate props with internals' do 
      @parser.internals["mk1PodCockpit"][:props].should == ["NavBall"]
    end
  end

  describe "others" do 
    it "should have discovered other 'unknown' things which are classed as 'other' and ignored" do 
  
      should_be_ignored = [
        "GameData/Squad/Agencies/Agents.cfg",
        "GameData/Squad/Resources/ScienceDefs.cfg",
        "GameData/BoulderCo/ActiveTextureManagerConfigs/KAS.cfg",
        "GameData/KerbPaint/Plugins/KerbPaint.cfg",
        "GameData/TweakScale/Kethane_TweakScale.cfg",
        "GameData/B9_Aerospace/Agencies/Agents.cfg", 
        "GameData/B9_Aerospace/ATM_B9_Aerospace.cfg",
        "GameData/KAS/addModule.cfg", 
        "GameData/KAS/settings.cfg"
      ]
      
      should_be_ignored.each do |ignored_cfg|
        @parser.ignored_cfgs.should be_include ignored_cfg
      end

    end
  end


  describe "ignore mods" do 
    before(:all) do 
      @parser = KerbalX::PartParser.new @path, :ignore_mods => ["NASAmission", "B9_Aerospace"]
    end

    it 'should not include part info from an ignored mod' do 
      @parser.parts.should_not have_key "B9.Cockpit.MK2"
      @parser.parts.should_not have_key "Size3AdvancedEngine"
    end

    it 'should not have resources from ignored mods' do  
      @parser.resources.should_not have_key "B9CompressedAir"
    end

    it 'should not have interntals from ignored mods' do 
      @parser.internals.should_not have_key "B9_Cockpit_HL_Internal"
    end

  end

  describe "with GameData not present" do 
    before(:all) do 
      @parser = KerbalX::PartParser.new File.join([Dir.getwd, "lib"])
    end

    it 'should not explode, just will not find any parts' do 
      @parser.parts.should be_empty
      @parser.ignored_cfgs.should be_empty
    end

  end


  describe "multipart part files" do 

    it 'should return multiple parts found in single file' do 
      @path = File.join(KerbalX.root, "test_env")
      @parser = KerbalX::PartParser.new @path
      @parser.should_receive(:discover_cfgs).and_return Dir.glob( File.join(@path, "GameData", "MechJeb2", "**", "*.cfg")).map{|p| p.split("test_env/").last}
      #raise @parser.discover_cfgs.inspect
      @parser.process
      @parser.parts.keys.should == ["mumech.MJ2.AR202", "mumech.MJ2.AR202.features1", "mumech.MJ2.AR202.features2", "mumech.MJ2.AR202.features3", "mumech.MJ2.AR202.features4", "mumech.MJ2.Pod"]

      
    
    end


  end


end

















#parts listed by the old PartParser, containes many things that are not parts.
=begin
["IRPiston", "IRPistonHalf", "IRPistonFourth", "IRHingeOpen", "IRHingeOpenHalf", "IRHingeOpenFourth", "ModulePaintable", "TweakScale", "dummyPartIgnore", "Part", "ModuleWheel", "ORSModuleResourceExtraction", "USI.ResourceConverter", "KarboniteGenerator", "ORSModuleAirScoop", "FissionRadiator", "FissionGenerator", "FissionReprocessor", "ModuleGenerator", "ModuleDeployableSolarPanel", "ModuleReactionWheel", "ModuleEngines", "ModuleEnginesFX", "ModuleRCS", "ModuleControlSurface", "ModuleResourceIntake", "RealFuels.ModuleFuelTanks", "ModuleSolarSail", "MicrowavePowerReceiver", "ISRUScoop", "AtmosphericIntake", "FNRadiator", "AlcubierreDrive", "FNNozzleController", "AntimatterStorageTank", "FNGenerator", "FNFusionReactor", "solidBooster", "liquidEngineMini", "radialEngineMini", "sepMotor1", "JetEngine", "fuelTank.long", "mk2SpacePlaneAdapter", "miniFuelTank", "mk1pod", "Mark1Cockpit", "Mark2Cockpit", "C7AerospaceDivision", "DinkelsteinKerman'sConstructionEmporium", "ExperimentalEngineeringGroup", "FLOOYDDynamicsResearchLabs", "GoliathNationalProducts", "IntegratedIntegrals", "IonicSymphonicProtonicElectronics", "JebediahKerman'sJunkyardandSpacecraftPartsCo", "KerbalMotionLLC", "KerbinWorld-FirstsRecord-KeepingSociety", "Kerbodyne", "KerlingtonModelRocketsandPaperProductsInc", "MaxoConstructionToys", "MovingPartsExpertsGroup", "O.M.B.DemolitionEnterprises", "PeriapsisRocketSuppliesCo", "ProbodobodyneInc", "Research&DevelopmentDepartment", "ReactionSystemsLtd", "RockomaxConglomerate", "RokeaInc", "Sean'sCannery", "STEADLEREngineeringCorps", "StrutCo", "Vac-CoAdvancedSuctionSystems", "WinterOwlAircraftEmporium", "ZaltonicElectronics", "Food", "B9.Control.RCS.Port.R1", "B9.Control.RCS.Block.R5", "B9.Control.RCS.Block.R12", "B9.Control.RCS.Block.R6", "B9.Utility.InfoDrive", "B9.Aero.T2.Tail", "B9.Cockpit.MK2", "B9.Rocket", "TetragonProjects", "Size3LargeTank", "MassiveBooster", "Size3AdvancedEngine"]

=end
 
