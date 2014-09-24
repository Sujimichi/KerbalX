#perhaps one of the most sophisticated logging systems that you will ever see.
#The intention is that this logger will be replaced with whatever logger is used 
#in the environment which the PartMapper is being used. However if none is given
#this provides the requried class methods
class KerbalX::Logger  
  def self.log_error args
    puts "OMG!! so....this happend\n"
    puts args
  end
end
