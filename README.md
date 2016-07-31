# KerbalX

A compnent of KerbalX.com, the craft sharing site for the Kerbal Space Program.
see http://KerbalX.com/about and http://KerbalX.com/PartMapper for more info.


A gem to scan the GameData folder in KSP and return details about the parts and which mods they belong to.
Provides a class to interface with KerbalX.com and transmit the information about discovered parts.


## Installation
Gem not relased on RubyGems, use github install

    gem "KerbalX", :git => "git@github.com:Sujimichi/KerbalX.git"

And then execute:

    $ bundle install

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



##Running Tests
The tests depend on a mock setup of a KSP GameData folder.  This mock setup contains some .cfg files from KSP core and 3rd party mods.
Basically it contains things that should not be distributed.  Therefore this data is contained in a password protected zip.
To run the tests you need to unzip test_env.zip and you'll need to ask me for the password in order to do so.

- I hope to change this, I'm just being over careful atm
- What is contained in the test_env is just .cfg files and only 1 or 2 from certain selected mods, so it shouldn't really be an issue.


##exe compilation
The PartMapper.exe is compiled using OCRA to package it up with the core ruby libs it needs to function in a windows environment which is devoid of ~~joy~~ Ruby.
Current version compiled under Ruby 2.2.5
Clone this projects repo and cd into dir.
Double check the @site variable, ensure it points to KerablX.com for production compile of part_mapper, or to test site for trail compiles.
    
    bundle install    #skip if already installed
    gem install ocra  #skip if already installed
    rake update       #builds the gem
    mkdir GameData #required so partmapper finds a GameData folder when compiled.
    
    ocra kerbalx_part_mapper.rb --no-enc --output 'PartMapper.exe'
    
    
    
    
