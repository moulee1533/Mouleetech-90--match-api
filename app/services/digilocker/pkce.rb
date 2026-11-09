require "digest"
require "base64"

module Digilocker
  class Pkce
    def self.generate
      verifier = SecureRandom.urlsafe_base64(64).tr("=", "")
      challenge = Base64.urlsafe_encode64(
        Digest::SHA256.digest(verifier),
        padding: false
      )
      { code_verifier: verifier, code_challenge: challenge, code_challenge_method: "S256" }
    end
  end
end
