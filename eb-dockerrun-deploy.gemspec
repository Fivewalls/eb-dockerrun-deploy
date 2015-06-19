# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eb/dockerrun/deploy/version'

Gem::Specification.new do |spec|
  spec.name          = "eb-dockerrun-deploy"
  spec.version       = Eb::Dockerrun::Deploy::VERSION
  spec.authors       = ["Ryan McIlmoyl"]
  spec.email         = ["ryan.mcilmoyl@gmail.com"]

  spec.summary       = "Deploy Dockerrun.aws.json from a template"
  spec.homepage      = "https://github.com/FXFusion/eb-dockerrun-deploy"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  #spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.executables = ["dockerrun_deploy"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "thor", "~> 0.19"
  spec.add_runtime_dependency "aws-sdk", "~> 2"
  spec.add_runtime_dependency "rubyzip", "~> 1.0"
  spec.add_runtime_dependency "activesupport", "~> 4"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
