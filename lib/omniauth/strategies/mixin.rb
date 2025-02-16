# frozen_string_literal: true

require "omniauth-oauth2"
require "json"
require "uri"
require "securerandom"

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

      credentials do
        hash = {
          "token" => access_token.token
        }
        hash["refresh_token"] = access_token.refresh_token if access_token.refresh_token
        hash["expires_at"] = access_token.expires_at if access_token.expires_at
        hash["expires"] = access_token.expires?
        hash["scope"] = access_token.params["scope"] || options[:scope] || OmniAuth::Mixin.configuration.scope
        hash
      end

      def build_access_token
        verifier = request.params["code"]
        client.get_token(
          {
            client_id: options.client_id,
            client_secret: options.client_secret,
            code: verifier,
            grant_type: "authorization_code",
            redirect_uri: callback_url
          }
        )
      rescue ::OAuth2::Error => e
        raise e # Simply re-raise the error for testing purposes
      rescue StandardError => e
        raise ::OAuth2::Error, e.message
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
        @client ||= ::OmniAuth::Strategies::Mixin::Client.new(
          options.client_id,
          options.client_secret,
          deep_symbolize(options.client_options).merge(
            connection_opts: {
              request: { timeout: 5, open_timeout: 2 }
            }
          )
        )
      end

      def valid_request?
        return false unless request.params["state"]
        return false unless session["omniauth.state"]

        request.params["state"] == session["omniauth.state"]
      end

      def authorize_params
        super.tap do |params|
          custom_state = request.params["state"]
          # Combine custom state with random data
          params[:state] = if custom_state
                             "#{custom_state}_#{SecureRandom.hex(8)}"
                           else
                             SecureRandom.hex(16)
                           end
          session["omniauth.state"] = params[:state]
        end
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
        error_hash = error.response.is_a?(Hash) ? error.response : JSON.parse(error.response.body)
        fail!(:invalid_credentials, error_hash)
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
