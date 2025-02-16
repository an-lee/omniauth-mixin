# frozen_string_literal: true

require "omniauth-oauth2"
require "json"

module OmniAuth
  module Strategies
    # OmniAuth strategy for authenticating with Mixin using OAuth2
    class Mixin < OmniAuth::Strategies::OAuth2
      option :name, "mixin"

      option :client_options, {
        site: "https://api.mixin.one",
        authorize_url: "https://mixin.one/oauth/authorize",
        token_url: "https://api.mixin.one/oauth/authorize"
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
        end
      end
    end
  end
end
