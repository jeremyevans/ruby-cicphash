require 'rake'
require 'rake/clean'
require 'rake/rdoctask'

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += ["--quiet", "--line-numbers", "--inline-source"]
  rdoc.main = "cicphash.rb"
  rdoc.title = "ruby-cicphash: Case Insensitive Case Preserving Hash"
  rdoc.rdoc_files.add ["cicphash.rb"]
end

desc "Update docs and upload to rubyforge.org"
task :doc_rforge => [:rdoc]
task :doc_rforge do
  sh %{chmod -R g+w rdoc/*}
  sh %{scp -rp rdoc/* rubyforge.org:/var/www/gforge-projects/cicphash}
end

desc "Package ruby-cicphash"
task :package do
  sh %{gem build cicphash.gemspec}
end
