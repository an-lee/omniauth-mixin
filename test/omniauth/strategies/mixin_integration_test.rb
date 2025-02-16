# frozen_string_literal: true

require "test_helper"
require "omniauth-oauth2"
require "json"

class MixinIntegrationTest < Minitest::Test
  def setup
    # Load credentials from environment variables or a config file
    @client_id = ENV["MIXIN_CLIENT_ID"]
    @client_secret = ENV["MIXIN_CLIENT_SECRET"]
    @access_token = ENV["MIXIN_TEST_ACCESS_TOKEN"]

    skip "Missing Mixin credentials for integration tests" unless credentials_present?

    @strategy = OmniAuth::Strategies::Mixin.new(
      nil,
      @client_id,
      @client_secret
    )
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
    user_data = auth_response.raw_info

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

  private

  def credentials_present?
    @client_id && @client_secret && @access_token
  end

  def make_api_request(endpoint)
    conn = Faraday.new(url: "https://api.mixin.one") do |faraday|
      faraday.headers["Authorization"] = "Bearer #{@access_token}"
      faraday.headers["Content-Type"] = "application/json"
      faraday.adapter Faraday.default_adapter
    end

    conn.get(endpoint)
  end

  def authenticate_with_token
    # Create a mock access token
    access_token = OAuth2::AccessToken.new(
      @strategy.client,
      @access_token,
      { "token_type" => "Bearer" }
    )

    # Mock the raw_info method to return actual API data
    @strategy.define_singleton_method(:raw_info) do
      conn = Faraday.new(url: "https://api.mixin.one") do |faraday|
        faraday.headers["Authorization"] = "Bearer #{access_token.token}"
        faraday.headers["Content-Type"] = "application/json"
        faraday.adapter Faraday.default_adapter
      end

      response = conn.get("/me")
      JSON.parse(response.body)["data"]
    end

    @strategy
  end
end
