FactoryBot.define do
  factory :staff_user do
    sequence(:username) { |n| "staff#{n}" }
    password { "Password1" }
    password_confirmation { "Password1" }
    full_name { "Staff User" }
    role { "admin" }
    active { true }
  end
end
