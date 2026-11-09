require "rails_helper"

RSpec.describe "Api::V1::Digilocker", type: :request do
  before do
    allow(Digilocker::Config).to receive(:mock?).and_return(true)
  end

  describe "GET /api/v1/digilocker/authorize" do
    let!(:user) { create(:user) }

    it "returns authorize_url for authenticated user" do
      get "/api/v1/digilocker/authorize", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json_body["authorize_url"]).to include("mock-code")
      expect(json_body["state"]).to be_present
      expect(DigilockerSession.where(user: user, status: "started").count).to eq(1)
    end

    it "accepts user_id query for registration flow" do
      get "/api/v1/digilocker/authorize", params: { user_id: user.id }
      expect(response).to have_http_status(:ok)
      expect(json_body["state"]).to be_present
    end
  end

  describe "GET /api/v1/digilocker/callback" do
    let!(:user) { create(:user) }
    let!(:session) { create(:digilocker_session, user: user) }

    it "completes verification in mock mode and returns JSON" do
      get "/api/v1/digilocker/callback", params: { code: "mock-code", state: session.state, format: "json" }

      expect(response).to have_http_status(:ok)
      expect(json_body["status"]).to eq("ok")
      expect(json_body["verification_required"]).to eq(false)
      expect(json_body["access_token"]).to be_present

      user.reload
      expect(user).to be_active
      expect(user.digilocker_verified?).to eq(true)
      expect(user.digilocker_raw_profile["eaadhaar_masked"]).to eq("XXXX-XXXX-1234")
      expect(session.reload.status).to eq("completed")
    end

    it "fails on invalid state" do
      get "/api/v1/digilocker/callback", params: { code: "mock-code", state: "bad", format: "json" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["reason"]).to eq("invalid state")
    end

    it "fails on expired session" do
      session.update!(expires_at: 1.minute.ago)
      get "/api/v1/digilocker/callback", params: { code: "mock-code", state: session.state, format: "json" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["reason"]).to eq("session expired")
    end
  end

  describe "GET /api/v1/digilocker/status" do
    it "returns verification status" do
      user = create(:user, :active)
      get "/api/v1/digilocker/status", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json_body["verified"]).to eq(true)
      expect(json_body["digilocker_id"]).to include("*")
    end
  end
end
