require 'rake'
require 'rake/clean'

RDOC_DEFAULT_OPTS = ["--quiet", "--line-numbers", "--inline-source", '--title', 'cicphash: Case Insensitive Case Preserving Hash']

rdoc_task_class = begin
  require "rdoc/task"
  RDOC_DEFAULT_OPTS.concat(['-f', 'hanna'])
  RDoc::Task
rescue LoadError
  require "rake/rdoctask"
  Rake::RDocTask
end

RDOC_OPTS = RDOC_DEFAULT_OPTS + ['--main', 'CICPHash']

rdoc_task_class.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.rdoc_files.add ["cicphash.rb"]
end


desc "Update docs and upload to rubyforge.org"
task :doc_rforge => [:rdoc]
task :doc_rforge do
  sh %{chmod -R g+w rdoc}
  sh %{rsync -rt rdoc/ rubyforge.org:/var/www/gforge-projects/cicphash/}
end


desc "Package ruby-cicphash"
task :package do
  sh %{#{FileUtils::RUBY} -S gem build cicphash.gemspec}
end


desc "Run tests"
task :default do
  sh %{#{FileUtils::RUBY} test/test_cicphash.rb}
end
