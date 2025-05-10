require 'rake'
require 'rake/clean'

desc "Generate rdoc"
task :rdoc do
  rdoc_dir = "rdoc"
  rdoc_opts = ["--line-numbers", "--inline-source", '--title', 'cicphash: Case Insensitive Case Preserving Hash']

  begin
    gem 'hanna'
    rdoc_opts.concat(['-f', 'hanna'])
  rescue Gem::LoadError
  end

  rdoc_opts.concat(['--main', 'README.rdoc', "-o", rdoc_dir] +
    %w"README.rdoc CHANGELOG MIT-LICENSE" +
    Dir["lib/**/*.rb"]
  )

  FileUtils.rm_rf(rdoc_dir)

  require "rdoc"
  RDoc::RDoc.new.document(rdoc_opts)
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
