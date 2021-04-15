# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shirinji/version'

Gem::Specification.new do |spec|
  spec.name          = 'shirinji'
  spec.version       = Shirinji::VERSION
  spec.authors       = ['Florian Dutey']
  spec.email         = ['fdutey@gmail.com']

  spec.summary       = 'Dependencies injection made easy'
  spec.description   = 'Dependencies injections made easy for Ruby'
  spec.homepage      = 'https://github.com/fdutey/shirinji'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
