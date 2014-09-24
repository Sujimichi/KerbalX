class HashWithIndifferentAccess < Hash
end

class Array
  def split n = []
    a =self.dup
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
end

class String
  def blank?
    self.nil? || self.empty?
  end
end

class NilClass
  def blank?
    true
  end
end
