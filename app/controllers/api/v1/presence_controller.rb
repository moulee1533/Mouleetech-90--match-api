module Api
  module V1
    class PresenceController < ApplicationController
      before_action :authenticate_user!

      def show
        user = User.find(params.require(:user_id))
        render json: {
          user_id: user.id,
          online: user.online?,
          last_seen_at: user.last_seen_at
        }
      end

      def heartbeat
        current_user.update_column(:last_seen_at, Time.current)
        render json: {
          user_id: current_user.id,
          online: true,
          last_seen_at: current_user.last_seen_at
        }
      end
    end
  end
end
