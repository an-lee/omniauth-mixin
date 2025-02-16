# frozen_string_literal: true

require "test_helper"

module Omniauth
  class TestMixin < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Omniauth::Mixin::VERSION
    end

    def test_strategy_name
      assert_equal "mixin", OmniAuth::Strategies::Mixin.new(nil).options.name
    end

    def test_client_options
      strategy = OmniAuth::Strategies::Mixin.new(nil)

      assert_equal "https://api.mixin.one", strategy.options.client_options.site
      assert_equal "https://mixin.one/oauth/authorize", strategy.options.client_options.authorize_url
      assert_equal "https://api.mixin.one/oauth/token", strategy.options.client_options.token_url
    end
  end
end
