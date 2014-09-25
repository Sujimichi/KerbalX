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

  it 'should extend Array with .split' do    
    [].split.should == [[]]
    [1,2,3,4,5].split(3).should == [ [1,2], [4,5] ]
    ["moo", "bar", "foo", "dar", "lar", "foo", "moo", "goo"].split("foo").should == [["moo", "bar"], ["dar", "lar"], ["moo", "goo"]] 
    ["moo", "bar", "foo", "dar", "lar", "foo", "moo", "goo"].split("jeb").should == [["moo", "bar", "foo", "dar", "lar", "foo", "moo", "goo"]]    
  end

end
