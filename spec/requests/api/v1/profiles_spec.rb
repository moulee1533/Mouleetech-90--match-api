require "rails_helper"

RSpec.describe "Api::V1::Profiles", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  def auth_headers_for(u)
    token = JsonWebToken.encode(
      user_id: u.id,
      jti: u.jti,
      verification_required: u.pending_verification?
    )
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end

  describe "PUT /api/v1/profile/basic" do
    it "saves basic details and advances signup_step" do
      put "/api/v1/profile/basic",
          params: {
            gender: "female",
            date_of_birth: "1995-08-20",
            height_cm: 160,
            marital_status: "never_married",
            religion: "Hindu",
            mother_tongue: "Tamil",
            profile_created_for: "self"
          }.to_json,
          headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["user"]["signup_step"]).to eq("family")
      expect(body["profile"]["basic"]["mother_tongue"]).to eq("Tamil")
    end
  end

  describe "PUT /api/v1/profile/update" do
    before do
      user.create_member_profile!(
        gender: "female",
        date_of_birth: "1995-08-20",
        height_cm: 160,
        marital_status: "never_married",
        religion: "Hindu",
        mother_tongue: "Tamil"
      )
      user.update!(signup_step: "done", profile_completed: true)
    end

    it "updates account + nested sections without changing signup_step" do
      put "/api/v1/profile/update",
          params: {
            full_name: "Updated Name",
            basic: { about_me: "Hello from Madurai", mother_tongue: "Telugu" },
            location: { country: "India", state: "Tamil Nadu", city: "Madurai" }
          }.to_json,
          headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["user"]["full_name"]).to eq("Updated Name")
      expect(body["user"]["signup_step"]).to eq("done")
      expect(body["profile"]["basic"]["about_me"]).to eq("Hello from Madurai")
      expect(body["profile"]["basic"]["mother_tongue"]).to eq("Telugu")
      expect(body["profile"]["location"]["city"]).to eq("Madurai")
      expect(body["profile_card"]).to be_present
    end

    it "returns validation errors for invalid nested data" do
      put "/api/v1/profile/update",
          params: { basic: { height_cm: 50 } }.to_json,
          headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Validation failed")
      expect(body["details"]).to be_present
    end

    it "requires auth" do
      put "/api/v1/profile/update",
          params: { full_name: "Nope" }.to_json,
          headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "full onboarding path" do
    it "completes profile steps then DigiLocker mock" do
      put "/api/v1/profile/basic",
          params: {
            gender: "male", date_of_birth: "1990-01-01", height_cm: 170,
            marital_status: "never_married", religion: "Hindu", mother_tongue: "Tamil"
          }.to_json, headers: headers
      expect(response).to have_http_status(:ok)

      put "/api/v1/profile/family",
          params: { family_type: "joint", family_values: "traditional" }.to_json,
          headers: headers
      expect(response).to have_http_status(:ok)

      put "/api/v1/profile/career",
          params: { highest_education: "Masters", employed_in: "private" }.to_json,
          headers: headers
      expect(response).to have_http_status(:ok)

      put "/api/v1/profile/location",
          params: { country: "India", state: "Tamil Nadu", city: "Madurai" }.to_json,
          headers: headers
      expect(response).to have_http_status(:ok)

      put "/api/v1/profile/partner",
          params: { age_min: 22, age_max: 30, religions: [ "Hindu" ] }.to_json,
          headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["user"]["profile_completed"]).to eq(true)
      expect(body["user"]["signup_step"]).to eq("digilocker")
      expect(body["user"]["onboarding_required"]).to eq(true)

      allow(Digilocker::Config).to receive(:mock?).and_return(true)
      get "/api/v1/digilocker/authorize", headers: headers
      authorize_url = JSON.parse(response.body)["authorize_url"]
      get authorize_url
      expect(response).to have_http_status(:ok)

      user.reload
      expect(user).to be_active
      expect(user.signup_step).to eq("done")
      expect(user.onboarding_required?).to eq(false)
    end
  end
end
