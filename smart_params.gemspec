#!/usr/bin/env ruby

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "smart_params/version"

Gem::Specification.new do |spec|
  spec.name = "smart_params"
  spec.version = SmartParams::VERSION
  spec.authors = ["Kurtis Rainbolt-Greene"]
  spec.email = ["kurtis@rainbolt-greene.online"]
  spec.summary = %q{Apply an organized and easy to maintain schema to request params}
  spec.description = spec.summary
  spec.homepage = "http://krainboltgreene.github.io/smart_params"
  spec.license = "ISC"

  spec.files = Dir[File.join("lib", "**", "*"), "LICENSE", "README.md", "Rakefile"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "rake", "~> 12.2"
  spec.add_development_dependency "pry", "~> 0.11"
  spec.add_development_dependency "pry-doc", "~> 0.11"
  spec.add_runtime_dependency "activesupport", "~> 5.1"
  spec.add_runtime_dependency "dry-monads", "~> 0.4"
  spec.add_runtime_dependency "dry-types", "~> 0.12"
  spec.add_runtime_dependency "recursive-open-struct", "~> 1.1"
end
