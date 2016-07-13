#perhaps one of the most sophisticated logging systems that you will ever see.
#The intention is that this logger will be replaced with whatever logger is used 
#in the environment which the PartMapper is being used. However if none is given
#this provides the requried class methods
class KerbalX::Logger  
  def self.log_error args
    puts "OMG!! so....this happend\n"
    puts args
  end

  attr_accessor :errors, :silent, :halt_on_error

  def initialize args = {}
    defs = {:halt_on_error => false, :silent => false}  
    args = defs.merge(args)
    @halt_on_error = args[:halt_on_error] 
    @silent = args[:silent]
    @errors = []
  end

  #Record an error and if @verbose is true print to screen as they occur
  def log_error error
    raise error.inspect if @halt_on_error
    puts [error].flatten.join("\n") unless @silent
    @errors << error
    return nil
  end

end
