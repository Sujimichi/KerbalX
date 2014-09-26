# KerbalX

A compnent of KerbalX.com, the craft sharing site for the Kerbal Space Program.
see http://KerbalX.com/about and http://KerbalX.com/PartMapper for more info.


A gem to scan the GameData folder in KSP and return details about the parts and which mods they belong to.
Also provides a class to interface with KerbalX.com and transmit the information about discovered parts.


## Installation
Gem not relased on RubyGems (yet), github install

    gem "wicked_pdf", :git => "git://github.com

And then execute:

    $ bundle

## Usage

### PartParser

    parser = KerbalX::PartParser.new <path_to_KSP_install>
    parser.parts #=> Hash of part names and details 
      
### KerbalX.com Interface      

    @path = <path_to_KSP_install>
    KerbalX::Interface.new(KerbalX::AuthToken.new(@path)) do |kerbalx|
      kerbalx.update_knowledge_base_with KerbalX::PartParser.new(@path).parts
    end
    
More instructions and more functionality will be added soon    
