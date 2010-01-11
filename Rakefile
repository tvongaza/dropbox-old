require 'rake'
require 'spec/rake/spectask'

desc "Run all examples"
Spec::Rake::SpecTask.new('examples') do |t|
  t.spec_files = FileList['examples/**/*.rb']
  t.libs << 'lib'
  t.spec_opts = %w[-c -fs]
  t.ruby_opts = %w[-rubygems]
end

task :default => :examples
