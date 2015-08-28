# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'boxchief/version'

Gem::Specification.new do |spec|
  spec.name          = "boxchief"
  spec.version       = Boxchief::VERSION
  spec.authors       = ["Alan Graham"]
  spec.email         = ["alan@productlab.com"]
  spec.summary       = %q{Helper gem for BoxChief.com}
  spec.description   = %q{Helper gem for BoxChief.com}
  spec.homepage      = "http://boxchief.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  spec.add_dependency 'usagewatch', '~> 0.0.7'
  spec.add_dependency 'sys-proctable', '~> 0.9.4'
  spec.add_dependency 'sys-filesystem', '~> 1.1.3'
  spec.add_dependency 'faraday', '~> 0.9.0'
  spec.add_dependency 'activesupport'
end
