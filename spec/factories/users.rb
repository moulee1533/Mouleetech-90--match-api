FactoryBot.define do
  factory :user do
    sequence(:phone) { |n| format("9%09d", n) }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password1" }
    password_confirmation { "Password1" }
    full_name { "Test User" }
    status { "pending_verification" }

    trait :active do
      status { "active" }
      digilocker_id { SecureRandom.hex(8) }
      digilocker_subject { digilocker_id }
      digilocker_verified_at { Time.current }
      digilocker_raw_profile do
        {
          "sub" => digilocker_id,
          "name" => full_name,
          "mode" => "hardcoded_temp"
        }
      end
    end

    trait :suspended do
      status { "suspended" }
    end
  end
end
