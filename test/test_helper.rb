# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "omniauth/mixin"

require "minitest/autorun"
require "mocha/minitest"
require "dotenv"
require "faraday"

# Load environment variables from .env file
Dotenv.load
