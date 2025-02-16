# frozen_string_literal: true

require_relative "lib/omniauth/mixin/version"

Gem::Specification.new do |spec|
  spec.name = "omniauth-mixin"
  spec.version = Omniauth::Mixin::VERSION
  spec.authors = ["an-lee"]
  spec.email = ["an.lee.work@gmail.com"]

  spec.summary = "OmniAuth OAuth2 strategy for Mixin"
  spec.description = "A Ruby gem for OmniAuth OAuth2 strategy for Mixin authentication"
  spec.homepage = "https://github.com/an-lee/omniauth-mixin"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/an-lee/omniauth-mixin"
  spec.metadata["changelog_uri"] = "https://github.com/an-lee/omniauth-mixin/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  File.basename(__FILE__)
  spec.files = Dir.glob("{lib}/**/*") + %w[LICENSE.txt README.md]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "omniauth", "~> 2.0"
  spec.add_dependency "omniauth-oauth2", "~> 1.8"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.add_development_dependency "mocha", "~> 2.1"
end
