# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'commendo/version'

Gem::Specification.new do |spec|
  spec.name          = 'commendo'
  spec.version       = Commendo::VERSION
  spec.authors       = ['Rob Styles']
  spec.email         = ['rob.styles@dynamicorange.com']
  spec.summary       = 'A Jaccard-similarity recommender using Redis sets'
  spec.description   = 'A Jaccard-similarity recommender using Redis sets'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'redis'
  spec.add_dependency 'mysql'
  spec.add_dependency 'progressbar'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'minitest', '~> 5.0.8'
end
