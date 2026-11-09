module Authenticable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
  end

  private

  def authenticate_user!
    token = bearer_token
    payload = token.present? ? JsonWebToken.decode(token) : nil
    user = payload && User.find_by(id: payload[:user_id], jti: payload[:jti])

    if user.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    if user.suspended?
      render json: { error: "Account suspended" }, status: :forbidden
      return
    end

    @current_user = user
    @token_payload = payload
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    return nil unless header.start_with?("Bearer ")

    header.split(" ", 2).last
  end

  def issue_token(user)
    JsonWebToken.encode({
      user_id: user.id,
      jti: user.jti,
      verification_required: user.pending_verification?
    })
  end

  def token_response(user)
    {
      access_token: issue_token(user),
      token_type: "Bearer",
      expires_in: JsonWebToken.expiry_seconds.to_i,
      verification_required: user.pending_verification?,
      user: UserSerializer.call(user)
    }
  end
end
