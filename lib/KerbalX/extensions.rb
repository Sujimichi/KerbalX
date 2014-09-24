#These extensions add a couple of Rails methods which are not present in pure Ruby

#simply allows HashWithIndifferentAccess to be called but doesn't add any changes
#to the base Hash class.  HashWithIndifferentAccess is only required in a section
#of PartParser which is not requied by KerbalX, only required in Jebretary (which
#is a Rails environment so HashWithIndifferentAccess is provided by rails)
class HashWithIndifferentAccess < Hash
end

#Add split and blank? to array
class Array

  #splits an array on a given element
  #ie [1,2,3,4,5].split(3) => [[1, 2], [4, 5]] 
  def split n = []
    a = self.dup
    b = []
    while a.include?(n)
      b << a[0..a.index(n)-1]
      a =  a[a.index(n)+1..a.size]
    end
    b << a
    b
  end

  def blank?
    self.nil? || self.empty?
  end

  def moo
    puts "baa"
  end

end

#add .blank? to String
class String
  def blank?
    self.nil? || self.empty?
  end
end

#and .blank? to nil
class NilClass
  def blank?
    true
  end
end
