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

    #array of arrays of version numbers SORTED CORRECTLY
    #before each test the array of version numbers will be sorted by random and the assertion is they should 
    #end up as they are here once sort_by_version is called.
    [
      ["0.30", "1:v0.30"],
      ["R5.2.6", "R5.2.7", "R5.2.8"],
      ["v8.0", "8.1", "v8.1", "v10.0"],
      ["0.5.4", "0.8.0", "0.8.1", "1:0.7.1.0"],
      [ "1.4", "Version_1.4.1", "1.4.2", "1.5", "v1.5.1"],
      ["7-4", "1:EVE-1.05-1", "1:EVE-1.05-2", "1:EVE-1.05-3", "1:EVE-1.05-4"],       
      ["ksp1.0_release1", "ksp1.0_r2", "ksp1.0_release2", "1:ksp1.0_r2","1:1.1.0"],
      ["Alpha_1.7c", "Beta_1.8g", "Beta_1.9a", "Beta_1.9f", "Beta_19.b", "1.9g", "1:1.9g"],
      ["foo-alpha-1.0.2", "foo-alpha-1.0.3", "foo-beta-1.0.1", "foo-beta-1.0.2", "foo-1.0.0"],
      ["v1.0.1-alpha", "v1.0.2-alpha", "v1.0.3-alpha", "v1.0.3-alpha-fix2", "v1.0.4-alpha", "v1.0.4b-alpha", "v1.0.5", "v1.0.6"],
      ["KerbalXMAS-1.0.ckan", "KerbalXMAS-1.001.ckan", "KerbalXMAS-1.03.ckan", "KerbalXMAS--1.05a.ckan", "KerbalXMAS-1.031.ckan", "KerbalXMAS-1.032.ckan", "KerbalXMAS-1.046.ckan", "KerbalXMAS-1.51.ckan"]       
    ].each do |test| 

      it "should sort array of version numbers to #{test}" do 
        unsorted = test.sort_by{rand}
        unsorted.sort_by_version.should == test      
      end

      it "should sort an array of objects with version numbers #{test}" do
        test = test.map{|v| {:version => v, :foo => :bar} }
        unsorted = test.sort_by{rand}
        unsorted.sort_by_version{|o| o[:version] }.should == test             
      end

    end
  
  end

end
