spec = Gem::Specification.new do |s| 
  s.name = "cicphash"
  s.version = "2.0.0"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.platform = Gem::Platform::RUBY
  s.summary = "Case Insensitive Case Preserving Hash"
  s.files = Dir['cicphash.rb']
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "MIT-LICENSE"]
  s.rdoc_options += ["--quiet", "--line-numbers", "--inline-source", '--title', 'CICPHash: Case Insensitive Case Preserving Hash', '--main', 'README.rdoc']
  s.require_path = "."
  s.test_files = Dir["test/test_cicphash.rb"]
  s.license = "MIT"
  s.homepage = "http://ruby-cicphash.jeremyevans.net"
  s.metadata          = { 
    'bug_tracker_uri'   => 'https://github.com/jeremyevans/ruby-cicphash/issues',
    'changelog_uri'     => 'https://github.com/jeremyevans/ruby-cicphash/blob/master/CHANGELOG',
    'documentation_uri' => 'http://ruby-cicphash.jeremyevans.net',
    'mailing_list_uri'  => 'https://github.com/jeremyevans/ruby-cicphash/discussions',
    "source_code_uri"   => 'https://github.com/jeremyevans/ruby-cicphash' 
  }
end
