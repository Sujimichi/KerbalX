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


  describe "sorting by version number" do 


    @data = [
      ["0.30", "1:v0.30"],
      ["R5.2.6", "R5.2.7", "R5.2.8"],
      ["v8.0", "8.1", "v8.1", "v10.0"],
      ["0.5.4", "0.8.0", "0.8.1", "1:0.7.1.0"],
      ["7-4", "1:EVE-1.05-1", "1:EVE-1.05-2", "1:EVE-1.05-3", "1:EVE-1.05-4"],       
      ["ksp1.0_release1", "ksp1.0_r2", "ksp1.0_release2", "1:ksp1.0_r2","1:1.1.0"],
      ["v1.0.1-alpha", "v1.0.2-alpha", "v1.0.3-alpha", "v1.0.3-alpha-fix2", "v1.0.4-alpha", "v1.0.4b-alpha", "v1.0.5", "v1.0.6"]
    ]
    $data = @data

    @data.each do |test| 

      it "should sort array of version numbers to #{test}" do 
        unsorted = test.sort_by{rand}
        unsorted.sort_v.should == test      
      end

    end
  
    it 'should simple test' do
      a = $data[5] 
      a.reverse.sort_v.should == a
    end

  end




=begin
  describe "sort_by_version" do 


    it('should sort versions'){ ["R5.2.8", "R5.2.6", "R5.2.7"  ].sort_by_version.should == ["R5.2.6", "R5.2.7", "R5.2.8"] }
    
    it('should sort versions'){ ["0.1", "0.1.2-fixed", "0.1.2" ].sort_by_version.should == ["0.1", "0.1.2", "0.1.2-fixed"] }

    it('should sort versions'){ ["8.1", "v10.0", "v8.1", "v8.0"].sort_by_version.should == ["v8.0", "v8.1", "8.1", "v10.0"] }

    it('should sort versions'){ ["foo-alpha-1.0.2", "foo-beta-1.0.2", "foo-alpha-1.0.3", "foo-1.0.0", "foo-beta-1.0.1"].sort_by_version.should == ["foo-alpha-1.0.2", "foo-alpha-1.0.3", "foo-beta-1.0.1", "foo-beta-1.0.2", "foo-1.0.0"] }

    it('should sort versions'){ ["KerbalXMAS-1.031.ckan", "KerbalXMAS-1.03.ckan", "KerbalXMAS-1.51.ckan", "KerbalXMAS--1.05a.ckan", "KerbalXMAS-1.046.ckan", "KerbalXMAS-1.032.ckan", "KerbalXMAS-1.001.ckan", "KerbalXMAS-1.0.ckan"].sort_by_version.should == ["KerbalXMAS-1.0.ckan", "KerbalXMAS-1.001.ckan", "KerbalXMAS-1.03.ckan", "KerbalXMAS--1.05a.ckan", "KerbalXMAS-1.031.ckan", "KerbalXMAS-1.032.ckan", "KerbalXMAS-1.046.ckan", "KerbalXMAS-1.51.ckan"] }

    it "should know the latest version for some exceptional(ly stupid) versions" do 


      a = ["CrewQueue-ksp1.0_release1.ckan", "CrewQueue-1-1.1.0.ckan", "CrewQueue-ksp1.0_release2.ckan", "CrewQueue-1-ksp1.0_r2.ckan", "CrewQueue-ksp1.0_r2.ckan"] 

      a.sort_by_version.last.should == "CrewQueue-1-1.1.0.ckan"

    end

  end
=end
end
