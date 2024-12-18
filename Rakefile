require 'rake'
require 'rake/clean'
require "rdoc/task"

RDOC_DEFAULT_OPTS = ["--quiet", "--line-numbers", "--inline-source", '--title', 'cicphash: Case Insensitive Case Preserving Hash']

begin
  gem 'hanna'
  RDOC_DEFAULT_OPTS.concat(['-f', 'hanna'])
rescue Gem::LoadError
end

RDOC_OPTS = RDOC_DEFAULT_OPTS + ['--main', 'README.rdoc']

RDoc::Task.new do |rdoc|
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
  sh %{#{FileUtils::RUBY} #{"-w" if RUBY_VERSION >= '3'} #{'-W:strict_unused_block' if RUBY_VERSION >= '3.4'} test/test_cicphash.rb}
end

desc "Run tests with coverage"
task :test_cov do
  ENV['COVERAGE'] = '1'
  sh "#{FileUtils::RUBY} test/test_cicphash.rb"
end
