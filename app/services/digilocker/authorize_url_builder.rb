module Digilocker
  class AuthorizeUrlBuilder
    Result = Struct.new(:authorize_url, :state, :session, keyword_init: true)

    def self.call(user:)
      new(user:).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      pkce = Digilocker::Pkce.generate
      state = SecureRandom.hex(24)

      session = DigilockerSession.create!(
        user: @user,
        state: state,
        code_verifier: pkce[:code_verifier],
        status: "started",
        expires_at: Digilocker::Config.session_ttl.from_now
      )

      if Digilocker::Config.mock?
        protocol = ENV.fetch("APP_PROTOCOL", "http")
        host = ENV.fetch("APP_HOST", "localhost")
        port = ENV.fetch("APP_PORT", "3000")
        authority = if (protocol == "https" && port == "443") || (protocol == "http" && port == "80")
                      host
                    else
                      "#{host}:#{port}"
                    end
        base = "#{protocol}://#{authority}"
        url = "#{base}/api/v1/digilocker/callback?#{ { code: 'mock-code', state: state, format: 'json' }.to_query }"
      else
        query = {
          response_type: "code",
          client_id: Digilocker::Config.client_id,
          redirect_uri: Digilocker::Config.redirect_uri,
          scope: Digilocker::Config.scopes,
          state: state,
          code_challenge: pkce[:code_challenge],
          code_challenge_method: pkce[:code_challenge_method]
        }
        url = "#{Digilocker::Config.authorize_url}?#{query.to_query}"
      end

      Result.new(authorize_url: url, state: state, session: session)
    end
  end
end
