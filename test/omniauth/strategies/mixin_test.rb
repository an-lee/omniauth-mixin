# frozen_string_literal: true

require "test_helper"
require "omniauth-oauth2"

class MixinStrategyTest < Minitest::Test
  def setup
    @client_id = "test_client_id"
    @client_secret = "test_client_secret"
    @options = {}
    @strategy = OmniAuth::Strategies::Mixin.new(nil, @client_id, @client_secret, @options)
  end

  def test_has_correct_site_url
    assert_equal "https://mixin.one", @strategy.options.client_options.site
  end

  def test_has_correct_authorize_url
    assert_equal "https://mixin.one/oauth/authorize", @strategy.options.client_options.authorize_url
  end

  def test_has_correct_token_url
    assert_equal "https://api.mixin.one/oauth/authorize", @strategy.options.client_options.token_url
  end

  def test_returns_info_hash
    raw_info = {
      "user_id" => "12345",
      "full_name" => "Test User",
      "identity_number" => "test@example.com",
      "avatar_url" => "http://example.com/avatar.jpg"
    }

    @strategy.stubs(:raw_info).returns(raw_info)

    expected_info = {
      name: "Test User",
      email: "test@example.com",
      nickname: "Test User",
      avatar: "http://example.com/avatar.jpg"
    }

    assert_equal expected_info, @strategy.info
  end

  def test_returns_uid_from_raw_info
    raw_info = { "user_id" => "12345" }
    @strategy.stubs(:raw_info).returns(raw_info)

    assert_equal "12345", @strategy.uid
  end

  def test_returns_raw_info_in_extra
    raw_info = {
      "user_id" => "12345",
      "full_name" => "Test User"
    }
    @strategy.stubs(:raw_info).returns(raw_info)

    assert_equal({ raw_info: raw_info }, @strategy.extra)
  end
end
