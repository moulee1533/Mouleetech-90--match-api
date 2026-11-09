require "net/http"
require "uri"
require "json"
require "digest"

module Digilocker
  class ProfileFetcher
    Error = Class.new(StandardError)

    def self.call(access_token:, user: nil)
      new(access_token:, user:).call
    end

    def initialize(access_token:, user: nil)
      @access_token = access_token
      @user = user
    end

    def call
      return mock_profile if Digilocker::Config.mock?

      uri = URI.join(Digilocker::Config.api_base_url.end_with?("/") ? Digilocker::Config.api_base_url : "#{Digilocker::Config.api_base_url}/", "oauth2/1/user")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@access_token}"
      request["Accept"] = "application/json"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      raise Error, "profile fetch failed (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

      sanitize(JSON.parse(response.body))
    rescue JSON::ParserError
      raise Error, "invalid profile response"
    end

    private

    def mock_profile
      # Unique per user so DIGILOCKER_MOCK can verify many local accounts.
      # Real DigiLocker returns a stable subject per citizen identity.
      subject = if @user&.id
                  "mock-digilocker-subject-#{@user.id}"
                else
                  "mock-digilocker-subject-001"
                end

      sanitize(
        {
          "sub" => subject,
          "name" => @user&.full_name.presence || "Mock Verified User",
          "dob" => "1995-01-15",
          "gender" => "M",
          "eaadhaar" => "XXXX-XXXX-1234"
        }
      )
    end

    # Never persist full Aadhaar; keep only masked/hashed claims.
    def sanitize(raw)
      aadhaar = raw["eaadhaar"] || raw["aadhaar"] || raw["uid"]
      {
        "sub" => raw["sub"] || raw["digilockerid"] || raw["digilocker_id"],
        "name" => raw["name"],
        "dob" => raw["dob"] || raw["date_of_birth"],
        "gender" => raw["gender"],
        "eaadhaar_masked" => mask_aadhaar(aadhaar),
        "eaadhaar_hash" => aadhaar.present? ? Digest::SHA256.hexdigest(aadhaar.to_s) : nil
      }.compact
    end

    def mask_aadhaar(value)
      return nil if value.blank?

      digits = value.to_s.gsub(/\D/, "")
      return "XXXX-XXXX-****" if digits.length < 4

      "XXXX-XXXX-#{digits[-4, 4]}"
    end
  end
end
