# frozen_string_literal: true

require "test_helper"
require "omniauth-oauth2"
require "json"
require_relative "../test_helpers/mixin_api_helpers"
require "logger"

class MixinBasicIntegrationTest < Minitest::Test
  include MixinApiHelpers

  def setup
    # Load credentials from environment variables or a config file
    @client_id = ENV.fetch("MIXIN_CLIENT_ID", nil)
    @client_secret = ENV.fetch("MIXIN_CLIENT_SECRET", nil)
    @access_token = ENV.fetch("MIXIN_TEST_ACCESS_TOKEN", nil)

    skip "Missing Mixin credentials for integration tests" unless credentials_present?

    @strategy = OmniAuth::Strategies::Mixin.new(
      nil,
      @client_id,
      @client_secret
    )

    @strategy.client.options[:debug] = true
    @strategy.client.options[:logger] = Logger.new($stdout)
  end

  def test_real_api_connection
    # Test basic API connectivity
    response = make_api_request("/me")

    assert_equal 200, response.status

    # Parse JSON response
    data = JSON.parse(response.body)

    assert data["data"]["user_id"], "Response should include user_id"
  end

  def test_real_auth_flow
    # This test requires manual intervention or a pre-authorized access token
    skip "Manual test for OAuth flow" unless @access_token

    auth_response = authenticate_with_token
    user_data = auth_response.raw_info || {}

    assert user_data["user_id"], "Should have a user ID"
    assert_equal auth_response.uid, user_data["user_id"]
    assert user_data["full_name"], "Should have a name"
  end

  def test_missing_fields
    skip "Manual test for OAuth flow" unless @access_token

    # Test with minimal user data
    @strategy.define_singleton_method(:raw_info) do
      { "user_id" => "12345" } # Minimal data
    end

    assert @strategy.uid, "Should have a uid even with minimal data"
    assert_nil @strategy.info[:name], "Should handle missing name"
  end

  def test_rate_limiting
    skip "Manual test for OAuth flow" unless @access_token

    # Test rapid requests
    5.times do
      response = make_api_request("/me")

      assert_includes [200, 429], response.status, "Should handle rate limits gracefully"
    end
  end

  def test_token_url_validity
    skip "Missing Mixin credentials for integration tests" unless credentials_present?
    response = exchange_token_request
    parsed_response = JSON.parse(response.body)

    assert_includes [400, 401, 202], response.status
    assert parsed_response.key?("error")
  end

  def test_raw_info
    skip "Missing Mixin credentials for integration tests" unless credentials_present?

    setup_strategy_with_access_token
    info = @strategy.raw_info

    assert info["user_id"], "Raw info should contain user_id"
    assert info["full_name"], "Raw info should contain full_name"
    assert info["identity_number"], "Raw info should contain identity_number"
  end

  private

  def setup_strategy_with_access_token
    access_token = OAuth2::AccessToken.new(
      @strategy.client,
      @access_token,
      { token_type: "Bearer" }
    )
    @strategy.instance_variable_set(:@access_token, access_token)
  end
end

class MixinTokenIntegrationTest < Minitest::Test
  include MixinApiHelpers

  def setup
    # Load credentials from environment variables or a config file
    @client_id = ENV.fetch("MIXIN_CLIENT_ID", nil)
    @client_secret = ENV.fetch("MIXIN_CLIENT_SECRET", nil)
    @access_token = ENV.fetch("MIXIN_TEST_ACCESS_TOKEN", nil)

    skip "Missing Mixin credentials for integration tests" unless credentials_present?

    @strategy = OmniAuth::Strategies::Mixin.new(
      nil,
      @client_id,
      @client_secret
    )

    @strategy.client.options[:debug] = true
    @strategy.client.options[:logger] = Logger.new($stdout)
  end

  def test_token_exchange_flow
    auth_code = ENV.fetch("MIXIN_TEST_AUTH_CODE", nil)
    skip "Missing Mixin credentials for integration tests" if auth_code.nil?

    # Create a mock request with full environment setup
    mock_request = stub("Request")
    mock_request.stubs(:scheme).returns("https")
    mock_request.stubs(:url).returns("https://example.com/auth/mixin/callback")
    mock_request.stubs(:params).returns({ "code" => auth_code })

    # Set up the full environment hash
    env = {
      "omniauth.error" => nil,
      "omniauth.error.type" => nil,
      "omniauth.error.strategy" => nil,
      "omniauth.origin" => nil,
      "rack.session" => {}
    }
    mock_request.stubs(:env).returns(env)
    mock_request.stubs(:session).returns({})

    strategy = OmniAuth::Strategies::Mixin.new(
      nil,
      @client_id,
      @client_secret,
      {
        provider_ignores_state: true
      }
    )
    strategy.stubs(:request).returns(mock_request)
    strategy.stubs(:callback_path).returns("/auth/mixin/callback")

    begin
      access_token = strategy.build_access_token

      assert_kind_of ::OAuth2::AccessToken, access_token, "Should return a valid OAuth2::AccessToken"

      user_info = strategy.raw_info

      assert user_info, "Should retrieve user info with token"
      assert user_info["user_id"], "User info should contain user_id"
    rescue StandardError => e
      puts "Error during token exchange: #{e.class} - #{e.message}"
      raise
    end
  end

  def test_token_exchange_error_handling
    skip "Missing Mixin credentials for integration tests" unless credentials_present?

    # Test with invalid authorization code
    invalid_code = "invalid_code"

    # Create a mock request
    mock_request = stub("Request")
    mock_request.stubs(:scheme).returns("https")
    mock_request.stubs(:url).returns("https://example.com/auth/mixin/callback")

    strategy = OmniAuth::Strategies::Mixin.new(
      nil,
      @client_id,
      @client_secret
    )
    strategy.stubs(:request).returns(mock_request)
    strategy.stubs(:callback_path).returns("/auth/mixin/callback")

    begin
      # Make a direct token request to ensure we get a proper response
      response = Faraday.post(strategy.options.client_options.token_url) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = {
          client_id: @client_id,
          client_secret: @client_secret,
          code: invalid_code,
          grant_type: "authorization_code"
        }.to_json
      end

      # The response should be a 401 or 400 for invalid code
      assert_includes [400, 401, 202], response.status
      parsed_response = JSON.parse(response.body)

      assert parsed_response.key?("error"), "Response should contain an error key"
    rescue Faraday::Error => e
      # If the request fails completely, that's also acceptable
      assert_match(/unauthorized|invalid/i, e.message)
    end
  end
end
