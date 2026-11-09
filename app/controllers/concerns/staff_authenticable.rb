module StaffAuthenticable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_staff
  end

  private

  def authenticate_staff!
    token = bearer_token
    payload = token.present? ? JsonWebToken.decode(token) : nil

    unless payload && payload[:type] == "staff"
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    staff = StaffUser.find_by(id: payload[:staff_user_id], jti: payload[:jti])

    if staff.nil? || !staff.active?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    @current_staff = staff
    @token_payload = payload
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    return nil unless header.start_with?("Bearer ")

    header.split(" ", 2).last
  end

  def issue_staff_token(staff)
    JsonWebToken.encode({
      type: "staff",
      staff_user_id: staff.id,
      jti: staff.jti,
      role: staff.role
    })
  end

  def staff_token_response(staff)
    {
      access_token: issue_staff_token(staff),
      token_type: "Bearer",
      expires_in: JsonWebToken.expiry_seconds.to_i,
      staff: StaffUserSerializer.call(staff)
    }
  end
end
