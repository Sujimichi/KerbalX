require 'spec_helper'



describe "extensions" do 


  it 'should extend' do 
    require File.join(File.dirname(__FILE__), "..","lib", "extensions")
    a = {}.blank?
    raise a.inspect
  end

end
