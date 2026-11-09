require "rails_helper"

RSpec.describe "Api::V1::Admin::Auth", type: :request do
  describe "POST /api/v1/admin/auth/login" do
    let!(:staff) { create(:staff_user, username: "admin", password: "Password1", password_confirmation: "Password1") }

    it "logs in with username and password" do
      post "/api/v1/admin/auth/login", params: { username: "admin", password: "Password1" }

      expect(response).to have_http_status(:ok)
      expect(json_body["access_token"]).to be_present
      expect(json_body["staff"]["username"]).to eq("admin")
      expect(json_body["staff"]["role"]).to eq("admin")
    end

    it "rejects invalid credentials" do
      post "/api/v1/admin/auth/login", params: { username: "admin", password: "WrongPass1" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects inactive staff" do
      staff.update!(active: false)
      post "/api/v1/admin/auth/login", params: { username: "admin", password: "Password1" }
      expect(response).to have_http_status(:forbidden)
    end

    it "requires username" do
      post "/api/v1/admin/auth/login", params: { password: "Password1" }
      expect(response).not_to have_http_status(:ok)
    end
  end
end
