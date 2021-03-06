# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sqltorial/metadata'

Gem::Specification.new do |spec|
  spec.name          = "sqltorial"
  spec.version       = SQLtorial::VERSION
  spec.authors       = ["Ryan Duryea"]
  spec.email         = ["aguynamedryan@gmail.com"]

  spec.summary       = SQLtorial::SUMMARY
  spec.description   = SQLtorial::DESCRIPTION
  spec.homepage      = SQLtorial::HOMEPAGE
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "sequelizer", "~> 0.0.6"
  spec.add_dependency "anbt-sql-formatter", "~> 0.0.3"
  spec.add_dependency "facets", "~> 3.0"
  spec.add_dependency "escort", "~> 0.4.0"
  spec.add_dependency "listen", "~> 3.0"
end
