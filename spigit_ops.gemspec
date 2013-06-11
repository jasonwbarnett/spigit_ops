# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spigit_ops/version'

Gem::Specification.new do |spec|
  spec.name          = "spigit_ops"
  spec.version       = SpigitOps::VERSION
  spec.authors       = ["Jason Barnett", "Bob Santos"]
  spec.email         = ["J@sonBarnett.com", "bob.santos@spigit.com"]
  spec.description   = %q{This gem does this and that.}
  spec.summary       = %q{Want to manage Spigit? Grab this gem.}
  spec.homepage      = "http://www.spigit.com/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'nokogiri', '>= 1.5.9'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
