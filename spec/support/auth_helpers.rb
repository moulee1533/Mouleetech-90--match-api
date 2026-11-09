module AuthHelpers
  def auth_headers(user)
    token = JsonWebToken.encode({
      user_id: user.id,
      jti: user.jti,
      verification_required: user.pending_verification?
    })
    { "Authorization" => "Bearer #{token}" }
  end

  def json_body
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
