module Digilocker
  class Config
    class << self
      def mock?
        ActiveModel::Type::Boolean.new.cast(ENV.fetch("DIGILOCKER_MOCK", "false"))
      end

      def client_id
        ENV.fetch("DIGILOCKER_CLIENT_ID", "mock-client-id")
      end

      def client_secret
        ENV.fetch("DIGILOCKER_CLIENT_SECRET", "mock-client-secret")
      end

      def redirect_uri
        ENV.fetch("DIGILOCKER_REDIRECT_URI", "http://localhost:3000/api/v1/digilocker/callback")
      end

      def authorize_url
        ENV.fetch("DIGILOCKER_AUTHORIZE_URL", "https://digilocker.meripehchaan.gov.in/public/oauth2/1/authorize")
      end

      def token_url
        ENV.fetch("DIGILOCKER_TOKEN_URL", "https://digilocker.meripehchaan.gov.in/public/oauth2/1/token")
      end

      def api_base_url
        ENV.fetch("DIGILOCKER_API_BASE_URL", "https://api.digitallocker.gov.in")
      end

      def scopes
        ENV.fetch("DIGILOCKER_SCOPES", "openid profile")
      end

      def deep_link_success
        ENV.fetch("APP_DEEP_LINK_SUCCESS", "ninetiesmatch://digilocker/success")
      end

      def deep_link_failure
        ENV.fetch("APP_DEEP_LINK_FAILURE", "ninetiesmatch://digilocker/failure")
      end

      def session_ttl
        ENV.fetch("DIGILOCKER_SESSION_TTL_SECONDS", "600").to_i.seconds
      end
    end
  end
end
