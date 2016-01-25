#These extensions add a couple of Rails methods which are not present in pure Ruby

#simply allows HashWithIndifferentAccess to be called but doesn't add any changes
#to the base Hash class.  HashWithIndifferentAccess is only required in a section
#of PartParser which is not requied by KerbalX, only required in Jebretary (which
#is a Rails environment so HashWithIndifferentAccess is provided by rails)
class HashWithIndifferentAccess < Hash
end

#Add split and .blank? to array
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
      b[1..-1]
    else
      [a]
    end    
  end

  def blank?
    self.nil? || self.empty?
  end
end

#add .blank? to String
class String
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

#and .blank? to nil
class NilClass
  def blank?
    true
  end
end
