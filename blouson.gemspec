# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blouson/version'

Gem::Specification.new do |spec|
  spec.name          = "blouson"
  spec.version       = Blouson::VERSION
  spec.authors       = ["Cookpad Inc."]
  spec.email         = ["kaihatsu@cookpad.com"]

  spec.summary       = %q{Filter tools to mask sensitive data in various logs}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/cookpad/blouson"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'rails'
  spec.add_dependency 'sentry-raven'

  spec.add_development_dependency 'arproxy'
  spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'pry'

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
