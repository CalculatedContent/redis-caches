spec = Gem::Specification.new do |s|
  s.name = "redis-caches"
  s.version = "0.1"
  s.author = "Charles H. Martin, PhD"
  s.homepage    = "http://github.com/CalculatedContent/redis-caches"
  s.rubyforge_project = "redis-caches"
  s.platform = Gem::Platform::RUBY
  s.summary     = "Redis Caches serializes a redis namespace to s3"
  s.require_path = "lib"

  s.add_dependency "redis", ">=3.0.3"   
  s.add_dependency "hiredis", "~> 0.4.5"
  s.add_dependency "redis-namespace", ">=1.2.1"

  s.add_development_dependency "rake", ">=10.0.0"
  s.add_development_dependency "rspec", ">=2.12.0"



  s.files = %w[
    LICENSE.txt
    CHANGELOG.rdoc
    README.rdoc
    Rakefile
  ] + Dir['lib/**/*.rb']

  s.test_files = Dir['spec/*.rb']
end
