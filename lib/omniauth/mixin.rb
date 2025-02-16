# frozen_string_literal: true

require_relative "mixin/version"
require "omniauth/strategies/mixin"
require "omniauth/strategies/mixin/client"
require "omniauth/mixin/configuration"

module Omniauth
  module Mixin
    class Error < StandardError; end
  end
end
