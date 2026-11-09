module Api
  module V1
    class DashboardController < ApplicationController
      before_action :authenticate_user!

      def show
        preview = MemberDirectory.preview_for(current_user, limit: 5)

        render json: {
          user: {
            id: current_user.id,
            full_name: current_user.full_name,
            digilocker_verified: current_user.digilocker_verified?,
            profile_completed: current_user.profile_completed?,
            status: current_user.status
          },
          interests: {
            received_pending: current_user.received_interests.pending.count,
            sent_pending: current_user.sent_interests.pending.count,
            accepted: Interest.accepted.where(
              "from_user_id = :id OR to_user_id = :id", id: current_user.id
            ).count
          },
          todays_matches: {
            count: preview.size,
            profiles: preview.map { |u| MemberCardSerializer.call(u) }
          }
        }
      end
    end
  end
end
