class JsonWebToken
  ALGORITHM = "HS256"

  class << self
    def encode(payload)
      body = payload.to_h.symbolize_keys
      body[:exp] = expiry_seconds.from_now.to_i
      JWT.encode(body, secret, ALGORITHM)
    end

    def decode(token)
      body = JWT.decode(token, secret, true, { algorithm: ALGORITHM }).first
      ActiveSupport::HashWithIndifferentAccess.new(body)
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    def expiry_seconds
      ENV.fetch("JWT_EXPIRY_SECONDS", "86400").to_i.seconds
    end

    private

    def secret
      ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }
    end
  end
end
