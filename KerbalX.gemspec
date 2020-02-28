# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'KerbalX/version'

Gem::Specification.new do |spec|
  spec.name          = "KerbalX"
  spec.version       = KerbalX::VERSION
  spec.authors       = ["sujimichi"]
  spec.email         = ["sujimichi@gmail.com"]
  spec.summary       = "Part Parser for KSP"
  spec.description   = "Tools for performing support actions on client machines or CKAN-mod-reader server"
  spec.homepage      = "http://KerablX.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler",    "~> 1.6"
  spec.add_development_dependency "rake",       '>= 10.3.2', '~> 13.0'
  spec.add_development_dependency "rspec",      '~> 3.1', '>= 3.1.0'
  spec.add_development_dependency "guard-rspec",'~> 4.3', '>= 4.3.1'
  spec.add_development_dependency 'progressbar','~> 0.21', '>= 0.21.0'
  spec.add_development_dependency 'rubyzip',    '~> 0.9', '>= 0.9.9'
  spec.add_development_dependency 'open_uri_redirections', '~> 0.2.1', '>= 0.2.1'

end
