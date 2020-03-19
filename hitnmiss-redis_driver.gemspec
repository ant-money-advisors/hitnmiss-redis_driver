# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hitnmiss/redis_driver-version'

Gem::Specification.new do |spec|
  spec.name          = "hitnmiss-redis_driver"
  spec.version       = Hitnmiss::RedisDriver::VERSION
  spec.authors       = ["Andrew De Ponte"]
  spec.email         = ["cyphactor@gmail.com"]

  spec.summary       = %q{Redis driver for Hitnmiss cache library}
  spec.description   = %q{Redis driver for Hitnmiss cache library}
  spec.homepage      = "https://github.com/Acornsgrow/hitnmiss-redis_driver"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "hitnmiss", "~> 2.0"
  spec.add_dependency "redis", ">= 3.2"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
	spec.add_development_dependency "simplecov", "~> 0.11"
	spec.add_development_dependency "codeclimate-test-reporter", "~> 0.4"
end
