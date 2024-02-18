#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/smart_params/version"

Gem::Specification.new do |spec|
  spec.name = "smart_params"
  spec.version = SmartParams::VERSION
  spec.authors = ["Kurtis Rainbolt-Greene"]
  spec.email = ["kurtis@rainbolt-greene.online"]
  spec.summary = "Apply an organized and easy to maintain schema to request params"
  spec.description = spec.summary
  spec.homepage = "https://github.com/krainboltgreene/smart_params.rb"
  spec.license = "HL3"
  spec.required_ruby_version = "~> 3.2"

  spec.files = Dir[File.join("lib", "**", "*"), "LICENSE", "README.md", "Rakefile"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", "~> 7.0"
  spec.add_runtime_dependency "dry-types", "~> 1.7"
  spec.metadata["rubygems_mfa_required"] = "true"
end
