require "net/http"
require "uri"
require "json"

module Digilocker
  class TokenExchanger
    Error = Class.new(StandardError)

    def self.call(code:, code_verifier:)
      new(code:, code_verifier:).call
    end

    def initialize(code:, code_verifier:)
      @code = code
      @code_verifier = code_verifier
    end

    def call
      return mock_token if Digilocker::Config.mock?

      uri = URI.parse(Digilocker::Config.token_url)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request.set_form_data(
        grant_type: "authorization_code",
        code: @code,
        redirect_uri: Digilocker::Config.redirect_uri,
        client_id: Digilocker::Config.client_id,
        client_secret: Digilocker::Config.client_secret,
        code_verifier: @code_verifier
      )

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      raise Error, "token exchange failed (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError
      raise Error, "invalid token response"
    end

    private

    def mock_token
      {
        "access_token" => "mock-access-token",
        "token_type" => "Bearer",
        "expires_in" => 3600,
        "id_token" => "mock-id-token"
      }
    end
  end
end
