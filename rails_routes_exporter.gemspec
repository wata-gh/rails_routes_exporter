# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rails_routes_exporter/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_routes_exporter"
  spec.version       = RailsRoutesExporter::VERSION
  spec.authors       = ["wata"]
  spec.email         = ["wata.gm@gmail.com"]

  spec.summary       = %q{Rails route exporter}
  spec.description   = %q{Rails route exporter}
  spec.homepage      = "https://github.com/wata-gh/rails_routes_exporter"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency 'aws-sdk-s3'
  spec.add_dependency 'diffy'

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
end
