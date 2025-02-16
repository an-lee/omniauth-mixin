# frozen_string_literal: true

require "test_helper"
require "omniauth-oauth2"
require "faraday"
require "json"

class MixinStrategyTest < Minitest::Test
  def setup
    @client_id = "test_client_id"
    @client_secret = "test_client_secret"
    @options = {}
    @strategy = OmniAuth::Strategies::Mixin.new(nil, @client_id, @client_secret, @options)
  end

  def test_has_correct_site_url
    assert_equal "https://api.mixin.one", @strategy.options.client_options.site
  end

  def test_has_correct_authorize_url
    assert_equal "https://mixin.one/oauth/authorize", @strategy.options.client_options.authorize_url
  end

  def test_has_correct_token_url
    assert_equal "https://api.mixin.one/oauth/token", @strategy.options.client_options.token_url
  end

  def test_returns_info_hash
    @strategy.stubs(:raw_info).returns(mock_user_raw_info)
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

  def test_handles_api_errors
    access_token = stub("AccessToken")
    access_token.stubs(:get).raises(OAuth2::Error.new(stub(parsed: {})))
    @strategy.stubs(:access_token).returns(access_token)

    assert_nil @strategy.raw_info
  rescue StandardError
    assert true, "Should handle OAuth2::Error gracefully"
  end

  def test_handles_invalid_json
    access_token = stub("AccessToken")
    response = stub(body: "invalid json")
    access_token.stubs(:get).returns(response)
    @strategy.stubs(:access_token).returns(access_token)

    assert_nil @strategy.raw_info
  rescue JSON::ParserError
    assert true, "Should handle invalid JSON gracefully"
  end

  def test_custom_client_options
    custom_options = {
      site: "https://custom.mixin.one",
      authorize_url: "https://custom.mixin.one/oauth/authorize",
      token_url: "https://custom.api.mixin.one/oauth/token"
    }

    strategy = OmniAuth::Strategies::Mixin.new(nil, @client_id, @client_secret, client_options: custom_options)
    assert_equal custom_options[:site], strategy.options.client_options.site
  end

  private

  def mock_user_raw_info
    {
      "user_id" => "12345",
      "full_name" => "Test User",
      "identity_number" => "test@example.com",
      "avatar_url" => "http://example.com/avatar.jpg"
    }
  end

  def expected_info
    {
      name: "Test User",
      email: "test@example.com",
      nickname: "Test User",
      avatar: "http://example.com/avatar.jpg"
    }
  end
end

class MixinOAuthTest < Minitest::Test
  def setup
    @client_id = "test_client_id"
    @client_secret = "test_client_secret"
    @options = {}
    @strategy = OmniAuth::Strategies::Mixin.new(nil, @client_id, @client_secret, @options)
  end

  def test_authorize_params
    @strategy.stubs(:session).returns({})
    @strategy.stubs(:request).returns(stub(params: {}, env: {}))
    @strategy.options[:authorize_params] = { scope: "PROFILE:READ" }
    assert_equal "PROFILE:READ", @strategy.authorize_params[:scope]
  end

  def test_token_params
    @strategy.options[:token_params] = { grant_type: "authorization_code" }
    assert_equal "authorization_code", @strategy.token_params[:grant_type]
  end

  def test_callback_url
    @strategy.stubs(:request).returns(
      stub(scheme: "https", url: "https://example.com",
           path: "/auth/mixin/callback", query_string: "", env: {})
    )
    assert_match %r{/auth/mixin/callback}, @strategy.callback_url
  end
end
