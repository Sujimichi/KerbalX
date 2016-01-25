#These extensions add a couple of Rails methods which are not present in pure Ruby

#simply allows HashWithIndifferentAccess to be called but doesn't add any changes
#to the base Hash class.  HashWithIndifferentAccess is only required in a section
#of PartParser which is not requied by KerbalX, only required in Jebretary (which
#is a Rails environment so HashWithIndifferentAccess is provided by rails)
class HashWithIndifferentAccess < Hash
end

#extensions for Array
class Array

  #splits an array on a given element
  #ie [1,2,3,4,5].split(3) => [[1, 2], [4, 5]] 
  def split n = []
    a = self.dup
    b = []
    if a.include?(n)
      while a.include?(n)
        b << a[0..a.index(n)-1]
        a =  a[a.index(n)+1..a.size]
      end    
      b << a
      b
    else
      [a]
    end    
  end

  #add .blank? to Array
  def blank?
    self.nil? || self.empty?
  end

  def sort_by_version    
    puts "not used"
    self.sort_by{ |version_number|
      version_number = version_number.dup.downcase
      version_number.gsub!("-","")
      version_number = "alpha" + version_number.gsub("alpha", "") if version_number.include?("alpha")
      version_number = "beta"  + version_number.gsub("beta",  "") if version_number.include?("beta")
      version_number = "v" + version_number unless version_number.match(/^v/)

      version_number.split(".").map{|component|   #split the version number by '.' -> version components
        component.split(/(\d+)/).map{|s|          #split each version component into alphas and numerics ie "v10" -> ["v", "10"] or "5-pre" -> ["5", "-pre"]
          (!!Float(s) rescue false) ? s.to_i : s  #convert strings that contain numerical values into Floats, otherwise remain as strings
        }
      }            
    }
  end

  def latest_version
    puts "not used"
    $version_sort_override ||= {}
    override = $version_sort_override.keys.select{|k| self.map{|i| i.include?(k)}.any?}.first
    if override
      return self.select{|i| i.include?($version_sort_override[override])}.first
    else
      return sort_by_version.last
    end
  end
end

#extensions for String class
class String

  #add .blank? to String
  def blank?
    self.nil? || self.empty?
  end

  # colorization
  def colorize color_code
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize 31
  end

  def green
    colorize 32
  end

  def yellow
    colorize 33
  end

  def blue
    colorize 34
  end

  def pink
    colorize 35
  end

  def light_blue
    colorize 36
  end
  
end

#extensions for Nil
class NilClass
  #and .blank? to nil
  def blank?
    true
  end
end
