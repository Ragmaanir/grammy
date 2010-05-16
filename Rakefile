
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.name = 'Grammy'
  s.version = '0.0.7'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README']
  s.summary = 'Grammy is a DSL to describe Grammars and gernerate LL Parsers'
  s.description = s.summary
  s.author = 'Ragmaanir'
  s.email = 'ragmaanir@gmail.com'
	s.homepage = 'http://ragmaanir.mypresident.de'
  s.files = %w(README Rakefile) + Dir.glob("{lib,spec}/**/*")
  s.require_path = "lib"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['README', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "Grammy Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Spec::Rake::SpecTask.new do |t|
	t.spec_opts = ['--options', "\"spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*.rb']
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('spec-cov') do |t|
  t.spec_opts = ['--options', "\"spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end
