require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:params) do
      {
        phone: "9876543210",
        password: "Password1",
        password_confirmation: "Password1",
        full_name: "New User"
      }
    end

    it "creates a pending user with phone login" do
      post "/api/v1/auth/register", params: params

      expect(response).to have_http_status(:created)
      body = json_body
      expect(body["user"]["phone"]).to eq("9876543210")
      expect(body["user"]["status"]).to eq("pending_verification")
      expect(body["user"]["profile_completed"]).to eq(false)
      expect(body["verification_required"]).to eq(true)
      expect(body["access_token"]).to be_present
      expect(body["digilocker"]).to be_nil
    end

    it "rejects weak passwords" do
      post "/api/v1/auth/register", params: params.merge(password: "password", password_confirmation: "password")
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) do
      create(:user, phone: "9123456780", password: "Password1", password_confirmation: "Password1")
    end

    it "logs in with phone and password" do
      post "/api/v1/auth/login", params: { phone: "9123456780", password: "Password1" }

      expect(response).to have_http_status(:ok)
      expect(json_body["access_token"]).to be_present
      expect(json_body["verification_required"]).to eq(true)
      expect(json_body["user"]["status"]).to eq("pending_verification")
    end

    it "rejects suspended users" do
      user.update!(status: "suspended")
      post "/api/v1/auth/login", params: { phone: "9123456780", password: "Password1" }
      expect(response).to have_http_status(:forbidden)
    end

    it "rejects invalid credentials" do
      post "/api/v1/auth/login", params: { phone: "9123456780", password: "WrongPass1" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/me" do
    let!(:user) { create(:user, :active) }

    it "returns the current user" do
      get "/api/v1/auth/me", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json_body["user"]["id"]).to eq(user.id)
    end

    it "rejects missing token" do
      get "/api/v1/auth/me"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/logout" do
    let!(:user) { create(:user, :active) }

    it "rotates jti so the old token stops working" do
      headers = auth_headers(user)
      post "/api/v1/auth/logout", headers: headers
      expect(response).to have_http_status(:ok)

      get "/api/v1/auth/me", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
