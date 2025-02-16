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

      def raw_info
        @raw_info ||= begin
          response = access_token.get("/me")
          JSON.parse(response.body)["data"]
        rescue ::OAuth2::Error, JSON::ParserError
          nil
        end
      end

      # Override callback_url to use modern URI parsing
      def callback_url
        full_host + callback_path
      end

      private

      def full_host
        uri = URI.parse(request.url)
        uri.path = ""
        uri.query = nil
        uri.fragment = nil
        uri.to_s
      end
    end
  end
end
