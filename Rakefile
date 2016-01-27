require "bundler/gem_tasks"

task :update do 
  system "gem uninstall KerbalX"
  system "gem build KerbalX.gemspec"
  system "gem install KerbalX-#{KerbalX::VERSION}.gem"
end

task :build do 
  system "gem build KerbalX.gemspec"
end

require 'rdoc'
require 'rdoc/task'
RDoc::Task.new :rdoc do |rdoc|
  rdoc.main = "README.md"
  rdoc.rdoc_files.include("README.md", "lib/**/*.rb")
  rdoc.title = "KerbalX ToolKit Documentation"
  rdoc.options << "--all" 
end
