# frozen_string_literal: true

# OmniAuth strategy for Mixin authentication
# Provides OAuth2 based authentication for Mixin Network
module OmniAuth
  # Mixin module for OmniAuth
  module Mixin
    # Configuration class for OmniAuth Mixin strategy
    # Handles customizable options for the authentication process
    class Configuration
      attr_accessor :scope, :prompt, :state_handler

      def initialize
        @scope = "PROFILE:READ"
        @prompt = nil
        @state_handler = -> { SecureRandom.hex(16) }
      end
    end

    class << self
      def configuration
        Thread.current[:omniauth_mixin_configuration] ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        Thread.current[:omniauth_mixin_configuration] = nil
      end
    end
  end
end
