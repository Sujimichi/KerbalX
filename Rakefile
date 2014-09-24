require "bundler/gem_tasks"

task :update do 
  system "gem uninstall KerbalX"
  system "gem build KerbalX.gemspec"
  system "gem install KerbalX-#{KerbalX::VERSION}.gem"
end
