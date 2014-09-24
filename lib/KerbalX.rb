require "KerbalX/version"

#extends Array with .split and .blank? and extends String and NilClass with .blank?
#extensions not required when used in a rails app as rails provides these extensions.
require "KerbalX/extensions" unless defined? Rails

require "KerbalX/part_parser"
require 'KerbalX/config'


module KerbalX
  # Your code goes here...  
  # or not as the case may be
end


class KerbalX::Config
  include Config
end

class KerbalX::PartParser
  include PartParser
end
