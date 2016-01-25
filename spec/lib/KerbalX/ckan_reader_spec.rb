require 'spec_helper'


class Array
  def sorted_to? assertion
    s = self.sort_by{|i| $reader.send(:sortable_version, i) } 
    if s == assertion
      return true
    else
      raise "array was incorrectly sorted; expected:\n#{assertion} but got:\n#{s}"
    end
  end
end
describe KerbalX::CkanReader do 

  describe "sorting by version number" do 
    before(:all) do 
      @path = File.join(File.dirname(__FILE__), "..", "test_env")
      @reader = KerbalX::CkanReader.new :dir => @path, :interface => KerbalX::Interface.new("site_url_here", KerbalX::AuthToken.new(@path))
      $reader = @reader
    end


    it('should sort versions'){ ["R5.2.8", "R5.2.6", "R5.2.7"  ].should be_sorted_to ["R5.2.6", "R5.2.7", "R5.2.8"] }
    
    it('should sort versions'){ ["0.1", "0.1.2-fixed", "0.1.2" ].should be_sorted_to ["0.1", "0.1.2", "0.1.2-fixed"] }

    it('should sort versions'){ ["8.1", "v10.0", "v8.1", "v8.0"].should be_sorted_to ["v8.0", "v8.1", "8.1", "v10.0"] }

    it('should sort versions'){ ["foo-alpha-1.0.2", "foo-beta-1.0.2", "foo-alpha-1.0.3", "foo-1.0.0", "foo-beta-1.0.1"].should be_sorted_to ["foo-alpha-1.0.2", "foo-alpha-1.0.3", "foo-beta-1.0.1", "foo-beta-1.0.2", "foo-1.0.0"] }

    it('should sort versions'){ ["KerbalXMAS-1.031.ckan", "KerbalXMAS-1.03.ckan", "KerbalXMAS-1.51.ckan", "KerbalXMAS--1.05a.ckan", "KerbalXMAS-1.046.ckan", "KerbalXMAS-1.032.ckan", "KerbalXMAS-1.001.ckan", "KerbalXMAS-1.0.ckan"].should be_sorted_to ["KerbalXMAS-1.0.ckan", "KerbalXMAS-1.001.ckan", "KerbalXMAS-1.03.ckan", "KerbalXMAS--1.05a.ckan", "KerbalXMAS-1.031.ckan", "KerbalXMAS-1.032.ckan", "KerbalXMAS-1.046.ckan", "KerbalXMAS-1.51.ckan"] }


    it "should know the latest version for some exceptional(ly stupid) versions" do 

      $version_sort_override = {
        "CrewQueue" => "1-1.1.0"
      }

      a = ["CrewQueue-ksp1.0_release1.ckan", "CrewQueue-1-1.1.0.ckan", "CrewQueue-ksp1.0_release2.ckan", "CrewQueue-1-ksp1.0_r2.ckan", "CrewQueue-ksp1.0_r2.ckan"] 

      a.sort_by{|i| $reader.send(:sortable_version, i) }.last.should == "CrewQueue-1-1.1.0.ckan" 

    end
   

  end

end
