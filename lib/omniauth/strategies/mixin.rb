# frozen_string_literal: true

require "omniauth-oauth2"
require "json"
require "uri"

module OmniAuth
  module Strategies
    # OmniAuth strategy for authenticating with Mixin using OAuth2
    class Mixin < OmniAuth::Strategies::OAuth2
      option :name, "mixin"

      option :client_options, {
        site: "https://api.mixin.one",
        authorize_url: "https://mixin.one/oauth/authorize",
        token_url: "https://api.mixin.one/oauth/token"
      }

      uid { raw_info&.dig("user_id") }

      info do
        {
          name: raw_info["full_name"],
          email: raw_info["identity_number"],
          nickname: raw_info["full_name"],
          avatar: raw_info["avatar_url"]
        }
      end

      extra do
        {
          raw_info: raw_info
        }
      end

      def build_access_token
        verifier = request.params["code"]
        client.auth_code.get_token(
          verifier,
          { redirect_uri: callback_url }.merge(token_params.to_hash(symbolize_keys: true)),
          deep_symbolize(options.auth_token_params || {})
        )
      rescue ::OAuth2::Error => e
        handle_token_error(e)
      rescue StandardError => e
        raise OmniAuth::Strategies::OAuth2::Error, e.message
      end

      def raw_info
        @raw_info ||= begin
          response = access_token.get("/me")
          parse_nested_response(response)
        rescue ::OAuth2::Error, JSON::ParserError => e
          handle_raw_info_error(e)
        end
      end

      # Override callback_url to use modern URI parsing
      def callback_url
        full_host + callback_path
      end

      def client
        ::OmniAuth::Strategies::Mixin::Client.new(
          options.client_id,
          options.client_secret,
          deep_symbolize(options.client_options)
        )
      end

      private

      def full_host
        uri = URI.parse(request.url)
        uri.path = ""
        uri.query = nil
        uri.fragment = nil
        uri.to_s
      end

      def parse_nested_response(response)
        parsed = JSON.parse(response.body)
        parsed["data"] || {}
      end

      def handle_token_error(error)
        if error.response&.body
          begin
            parsed = JSON.parse(error.response.body)
            if parsed["data"] && parsed["data"]["access_token"]
              return ::OAuth2::AccessToken.new(
                client,
                parsed["data"]["access_token"],
                {
                  refresh_token: parsed["data"]["refresh_token"],
                  expires_in: parsed["data"]["expires_in"],
                  token_type: parsed["data"]["token_type"] || "Bearer"
                }
              )
            end
          rescue JSON::ParserError
            # Handle invalid JSON response
            raise OmniAuth::Strategies::OAuth2::Error, error.response.body
          end
        end
        raise error
      end

      def handle_raw_info_error(error)
        log(:error, "Failed to get user info: #{error.message}")
        nil
      end

      def deep_symbolize(hash)
        hash.each_with_object({}) do |(key, value), result|
          result[key.to_sym] = value.is_a?(Hash) ? deep_symbolize(value) : value
        end
      end
    end
  end
end
