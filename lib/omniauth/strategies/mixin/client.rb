# frozen_string_literal: true

require "omniauth-oauth2"
require "json"

module OmniAuth
  module Strategies
    class Mixin
      # OAuth2 client implementation for Mixin Network authentication.
      # Handles token exchange and API communication with Mixin endpoints.
      class Client < ::OAuth2::Client
        def get_token(params, access_token_opts = {}, _extract_access_token = nil)
          response = request(:post, token_url, token_params(params))
          parsed = JSON.parse(response.body)

          if parsed["error"]
            error = parsed["error"]
            raise ::OAuth2::Error,
                  "Mixin API Error: #{error["description"]} (Status: #{error["status"]}, Code: #{error["code"]})"
          end

          token_data = parsed["data"]
          raise ::OAuth2::Error, "Invalid response format from Mixin API: missing data field" unless token_data

          ::OAuth2::AccessToken.new(
            self,
            token_data["access_token"],
            {
              refresh_token: token_data["refresh_token"],
              expires_in: token_data["expires_in"],
              token_type: token_data["token_type"] || "Bearer"
            }.merge(access_token_opts)
          )
        end

        private

        def token_params(params)
          {
            headers: { "Content-Type" => "application/json" },
            body: params.to_json
          }
        end
      end
    end
  end
end
