require "rails_helper"

RSpec.describe "Api::V1::Admin data", type: :request do
  let!(:staff) { create(:staff_user) }
  let!(:member) { create(:user, :active) }
  let!(:session) { create(:digilocker_session, user: member, status: "completed") }

  def staff_headers
    token = JsonWebToken.encode({
      type: "staff",
      staff_user_id: staff.id,
      jti: staff.jti,
      role: staff.role
    })
    { "Authorization" => "Bearer #{token}" }
  end

  it "requires staff auth for dashboard" do
    get "/api/v1/admin/dashboard"
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns dashboard counts" do
    get "/api/v1/admin/dashboard", headers: staff_headers
    expect(response).to have_http_status(:ok)
    expect(json_body["users_total"]).to be >= 1
    expect(json_body["digilocker_verified"]).to be >= 1
  end

  it "lists members" do
    get "/api/v1/admin/users", headers: staff_headers
    expect(response).to have_http_status(:ok)
    expect(json_body["data"]).to be_an(Array)
    expect(json_body["meta"]["total"]).to be >= 1
  end

  it "shows member with digilocker sessions" do
    get "/api/v1/admin/users/#{member.id}", headers: staff_headers
    expect(response).to have_http_status(:ok)
    expect(json_body["user"]["id"]).to eq(member.id)
    expect(json_body["digilocker_sessions"].first["id"]).to eq(session.id)
  end

  it "lists digilocker sessions" do
    get "/api/v1/admin/digilocker_sessions", headers: staff_headers
    expect(response).to have_http_status(:ok)
    expect(json_body["data"].first["user_email"]).to eq(member.email)
  end

  it "rejects member JWT on admin routes" do
    member_token = JsonWebToken.encode({
      user_id: member.id,
      jti: member.jti,
      verification_required: false
    })
    get "/api/v1/admin/dashboard", headers: { "Authorization" => "Bearer #{member_token}" }
    expect(response).to have_http_status(:unauthorized)
  end
end
