require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "DropBox"
    open("VERSION") do |f|
      gem.version = f.read
    end
    gem.summary = %Q{A Simple DropBox API in Ruby}
    gem.description = %Q{A Simple DropBox API in Ruby}
    gem.email = "jphastings@gmail.com"
    gem.homepage = "http://github.com/jphastings/DropBox"
    gem.authors = ["JP Hastings-Spital","github.com/chrissearle","github.com/tvongaza"]
    gem.add_development_dependency "Shoulda"
    gem.add_dependency "mechanize"
    gem.add_dependency "nokogiri"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

desc "Run all examples"
Spec::Rake::SpecTask.new('examples') do |t|
  t.spec_files = FileList['examples/**/*.rb']
  t.libs << 'lib'
  t.spec_opts = %w[-c -fs]
  t.ruby_opts = %w[-rubygems]
end

task :default => :examples
