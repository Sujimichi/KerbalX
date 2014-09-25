require 'spec_helper'

describe KerbalX::PartParser do 

  before(:all) do 
    @path = File.join(File.dirname(__FILE__), "..", "test_env")
    @parser = KerbalX::PartParser.new @path

  end

  it 'it should find the correct number of parts' do 
    #should be 28 parts
    #The complexity of this test is more in the setup of the test_env folder which contains a number of 
    #different .cfg files defining parts and other aspects (resources, settings, all kinda stuff)
    #There are also some part.cfgs that define multiple parts as well as the more common 1 part per cfg setup
    #includes Modules which modify parts (ie from TweakScale) which have in the past been falsly identifyed as parts
    #contains Agency definitions. 
    @parser.parts.keys.count.should == 28
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

end

 ["IRPiston", "IRPistonHalf", "IRPistonFourth", "IRHingeOpen", "IRHingeOpenHalf", "IRHingeOpenFourth", "ModulePaintable", "TweakScale", "dummyPartIgnore", "Part", "ModuleWheel", "ORSModuleResourceExtraction", "USI.ResourceConverter", "KarboniteGenerator", "ORSModuleAirScoop", "FissionRadiator", "FissionGenerator", "FissionReprocessor", "ModuleGenerator", "ModuleDeployableSolarPanel", "ModuleReactionWheel", "ModuleEngines", "ModuleEnginesFX", "ModuleRCS", "ModuleControlSurface", "ModuleResourceIntake", "RealFuels.ModuleFuelTanks", "ModuleSolarSail", "MicrowavePowerReceiver", "ISRUScoop", "AtmosphericIntake", "FNRadiator", "AlcubierreDrive", "FNNozzleController", "AntimatterStorageTank", "FNGenerator", "FNFusionReactor", "solidBooster", "liquidEngineMini", "radialEngineMini", "sepMotor1", "JetEngine", "fuelTank.long", "mk2SpacePlaneAdapter", "miniFuelTank", "mk1pod", "Mark1Cockpit", "Mark2Cockpit", "C7AerospaceDivision", "DinkelsteinKerman'sConstructionEmporium", "ExperimentalEngineeringGroup", "FLOOYDDynamicsResearchLabs", "GoliathNationalProducts", "IntegratedIntegrals", "IonicSymphonicProtonicElectronics", "JebediahKerman'sJunkyardandSpacecraftPartsCo", "KerbalMotionLLC", "KerbinWorld-FirstsRecord-KeepingSociety", "Kerbodyne", "KerlingtonModelRocketsandPaperProductsInc", "MaxoConstructionToys", "MovingPartsExpertsGroup", "O.M.B.DemolitionEnterprises", "PeriapsisRocketSuppliesCo", "ProbodobodyneInc", "Research&DevelopmentDepartment", "ReactionSystemsLtd", "RockomaxConglomerate", "RokeaInc", "Sean'sCannery", "STEADLEREngineeringCorps", "StrutCo", "Vac-CoAdvancedSuctionSystems", "WinterOwlAircraftEmporium", "ZaltonicElectronics", "Food", "B9.Control.RCS.Port.R1", "B9.Control.RCS.Block.R5", "B9.Control.RCS.Block.R12", "B9.Control.RCS.Block.R6", "B9.Utility.InfoDrive", "B9.Aero.T2.Tail", "B9.Cockpit.MK2", "B9.Rocket", "TetragonProjects", "Size3LargeTank", "MassiveBooster", "Size3AdvancedEngine"]
 
