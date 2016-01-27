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

  def sort_by_version &blk
    self.sort_by do |version|
      version = yield(version) if block_given? 

      #get epoch value. 
      v = version.split(":")
      epoch = v.size > 1 ? v.first.to_i : 0 #if the version contains a : take value before : to be epoch otherwise epoch is 0
      v = v.last.downcase #regardless of whether or not version contains :, .last will be rest of the version

      #handle sorting of versions with 'alpha' and 'beta' tags.
      cycle = v.include?("alpha") ? 0 : (v.include?("beta") ? 1 : 2) #score alpha as 0, beta as 1 and everything else as 2
      v = v.gsub("alpha", "").gsub("beta", "") #remove alpha and beta tags from version

      a = v.split(/[\d|\W]/)  #take the alpha compnent of the version
      a = [""] if a.empty?    #if there is no alpha compnent make it a single empty string
      n = v.split(/\D/).map{|i| i.to_i unless i.empty?}.compact #take the numeric compnent of the version
      
      #array will be sorted, first by epoch, then by cycle (alpha, beta, production), then by the numerical component and 
      #finally by any string component
      [epoch, cycle, n, a] 
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
