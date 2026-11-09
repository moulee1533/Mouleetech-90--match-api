FactoryBot.define do
  factory :digilocker_session do
    user
    state { SecureRandom.hex(24) }
    code_verifier { SecureRandom.urlsafe_base64(64).tr("=", "") }
    status { "started" }
    expires_at { 10.minutes.from_now }
  end
end
