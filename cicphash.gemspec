spec = Gem::Specification.new do |s| 
  s.name = "cicphash"
  s.version = "1.1.0"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.platform = Gem::Platform::RUBY
  s.summary = "Case Insensitive Case Preserving Hash"
  s.files = Dir['cicphash.rb']
  s.require_path = "."
  s.test_files = Dir["test/test_cicphash.rb"]
  s.has_rdoc = true
  s.rubyforge_project = 'cicphash'
  s.homepage = "http://cicphash.rubyforge.org"
end
