require 'rake'
require 'rake/clean'

RDOC_DEFAULT_OPTS = ["--quiet", "--line-numbers", "--inline-source", '--title', 'cicphash: Case Insensitive Case Preserving Hash']

begin
  gem 'hanna-nouveau'
  RDOC_DEFAULT_OPTS.concat(['-f', 'hanna'])
rescue Gem::LoadError
end

rdoc_task_class = begin
  require "rdoc/task"
  RDOC_DEFAULT_OPTS.concat(['-f', 'hanna'])
  RDoc::Task
rescue LoadError
  require "rake/rdoctask"
  Rake::RDocTask
end

RDOC_OPTS = RDOC_DEFAULT_OPTS + ['--main', 'README.rdoc']

rdoc_task_class.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.rdoc_files.add %w"cicphash.rb README.rdoc CHANGELOG MIT-LICENSE"
end

desc "Package ruby-cicphash"
task :package do
  sh %{#{FileUtils::RUBY} -S gem build cicphash.gemspec}
end

desc "Run tests"
task :default do
  sh %{#{FileUtils::RUBY} test/test_cicphash.rb}
end
