# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'filelock/version'

Gem::Specification.new do |spec|
  spec.name          = "rfilelock"
  spec.version       = Filelock::VERSION
  spec.authors       = [""]
  spec.email         = ["tsahil@weavingthings.com"]
  spec.description   = %q{Reentrant Filelock using sheerun/filelock and flock}
  spec.summary       = %q{Reentrant Filelock using sheerun/filelock and flock}
  spec.homepage      = "https://github.com/Produvia-Weaver/reentrant-filelock"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
