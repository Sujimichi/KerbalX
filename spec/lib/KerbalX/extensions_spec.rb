require 'spec_helper'

describe "extensions" do 

  it 'should extend String with .blank?' do 
    "".should be_blank
    "foo".should_not be_blank
  end

  it 'should extend NilClass with .blank?' do 
    nil.should be_blank
  end

  it 'should extend Array with .blank?' do 
    [].should be_blank
    ["foo"].should_not be_blank
  end

  it 'should extend Array with .split'  do    
    [].split.should == [[]]   
    [1,2,3,4,5].split(3).should == [ [1,2], [4,5] ]
    ["moo", "bar", "foo", "dar", "lar", "foo", "moo", "goo"].split("foo").should == [["moo", "bar"], ["dar", "lar"], ["moo", "goo"]] 
    ["moo", "bar", "foo", "dar", "lar", "foo", "moo", "goo"].split("jeb").should == [["moo", "bar", "foo", "dar", "lar", "foo", "moo", "goo"]]    
  end


  describe "sort_by_version" do 


    it('should sort versions'){ ["R5.2.8", "R5.2.6", "R5.2.7"  ].sort_by_version.should == ["R5.2.6", "R5.2.7", "R5.2.8"] }
    
    it('should sort versions'){ ["0.1", "0.1.2-fixed", "0.1.2" ].sort_by_version.should == ["0.1", "0.1.2", "0.1.2-fixed"] }

    it('should sort versions'){ ["8.1", "v10.0", "v8.1", "v8.0"].sort_by_version.should == ["v8.0", "v8.1", "8.1", "v10.0"] }

    it('should sort versions'){ ["foo-alpha-1.0.2", "foo-beta-1.0.2", "foo-alpha-1.0.3", "foo-1.0.0", "foo-beta-1.0.1"].sort_by_version.should == ["foo-alpha-1.0.2", "foo-alpha-1.0.3", "foo-beta-1.0.1", "foo-beta-1.0.2", "foo-1.0.0"] }

    it('should sort versions'){ ["KerbalXMAS-1.031.ckan", "KerbalXMAS-1.03.ckan", "KerbalXMAS-1.51.ckan", "KerbalXMAS--1.05a.ckan", "KerbalXMAS-1.046.ckan", "KerbalXMAS-1.032.ckan", "KerbalXMAS-1.001.ckan", "KerbalXMAS-1.0.ckan"].sort_by_version.should == ["KerbalXMAS-1.0.ckan", "KerbalXMAS-1.001.ckan", "KerbalXMAS-1.03.ckan", "KerbalXMAS--1.05a.ckan", "KerbalXMAS-1.031.ckan", "KerbalXMAS-1.032.ckan", "KerbalXMAS-1.046.ckan", "KerbalXMAS-1.51.ckan"] }

    it "should know the latest version for some exceptional(ly stupid) versions" do 

      $version_sort_override = {
        "CrewQueue" => "1-1.1.0"
      }

      a = ["CrewQueue-ksp1.0_release1.ckan", "CrewQueue-1-1.1.0.ckan", "CrewQueue-ksp1.0_release2.ckan", "CrewQueue-1-ksp1.0_r2.ckan", "CrewQueue-ksp1.0_r2.ckan"] 

      a.latest_version.should == "CrewQueue-1-1.1.0.ckan"

    end

  end

end
