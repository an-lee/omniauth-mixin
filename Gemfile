# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in omniauth-mixin.gemspec
gemspec

gem "rake", "~> 13.0"

gem "minitest", "~> 5.16"

gem "rubocop", "~> 1.21"

group :development, :test do
  gem "dotenv", "~> 2.8"
  gem "faraday", "~> 2.0"
  gem "mocha", "~> 2.1"
  gem "rubocop-minitest"
  gem "rubocop-performance"
  gem "rubocop-rake"
  gem "rubocop-thread_safety"
  gem "securerandom"
end

group :test do
  gem "vcr"
  gem "webmock"
end
