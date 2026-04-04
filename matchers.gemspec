# frozen_string_literal: true

require_relative "lib/matcher/version"

Gem::Specification.new do |spec|
  spec.name = "matchers"
  spec.version = Matcher::VERSION
  spec.authors = ["Rico Jasper"]
  spec.email = ["jasper.rico@gmail.com"]

  spec.summary = "Composable data structure matchers with error reporting"
  spec.description = <<~DESC
    A DSL for building matchers that validate nested data structures. \
    Ruby literals like classes, ranges, regexps, arrays, and hashes are \
    automatically converted into matchers. Mismatches produce error trees \
    with paths pointing to each failing element.
  DESC
  spec.homepage = "https://github.com/rjasper/ruby-matchers"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] =
    "https://github.com/rjasper/ruby-matchers"
  spec.metadata["changelog_uri"] =
    "https://github.com/rjasper/ruby-matchers/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"] - Dir["lib/matcher/archive/**/*"]
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
