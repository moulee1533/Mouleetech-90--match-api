module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token].presence
      token ||= request.headers["Authorization"].to_s.delete_prefix("Bearer ").presence
      payload = token.present? ? JsonWebToken.decode(token) : nil
      user = payload && User.find_by(id: payload[:user_id], jti: payload[:jti])
      return reject_unauthorized_connection if user.nil? || user.suspended?

      user
    end
  end
end
