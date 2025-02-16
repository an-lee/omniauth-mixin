# frozen_string_literal: true

module MixinApiHelpers
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
    access_token = create_access_token
    mock_raw_info_method(access_token)
    @strategy
  end

  def create_access_token
    OAuth2::AccessToken.new(
      @strategy.client,
      @access_token,
      { "token_type" => "Bearer" }
    )
  end

  def mock_raw_info_method(access_token)
    # Store the connection creation logic in a local variable
    conn = create_faraday_connection(access_token.token)

    @strategy.define_singleton_method(:raw_info) do
      response = conn.get("/me")
      JSON.parse(response.body)["data"]
    end
  end

  def create_faraday_connection(token)
    Faraday.new(url: "https://api.mixin.one") do |faraday|
      faraday.headers["Authorization"] = "Bearer #{token}"
      faraday.headers["Content-Type"] = "application/json"
      faraday.adapter Faraday.default_adapter
    end
  end

  def exchange_token_request
    Faraday.post(@strategy.options.client_options.token_url) do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = token_request_body.to_json
    end
  rescue Faraday::ConnectionFailed
    flunk "Token URL is not accessible: #{@strategy.options.client_options.token_url}"
  end

  def token_request_body
    {
      client_id: @client_id,
      client_secret: @client_secret,
      code: "test_auth_code",
      grant_type: "authorization_code"
    }
  end
end
