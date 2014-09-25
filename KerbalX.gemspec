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
  spec.description   = ""
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler",    "~> 1.6"
  spec.add_development_dependency "rake",       '~> 10.3', '>= 10.3.2'
  spec.add_development_dependency "rspec",      '~> 3.1', '>= 3.1.0'
  spec.add_development_dependency "guard-rspec",'~> 4.3', '>= 4.3.1'
end
