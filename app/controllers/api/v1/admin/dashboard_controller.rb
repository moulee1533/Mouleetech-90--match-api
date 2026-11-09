module Api
  module V1
    module Admin
      class DashboardController < BaseController
        def show
          render json: {
            users_total: User.count,
            users_by_status: User.group(:status).count,
            digilocker_verified: User.where.not(digilocker_verified_at: nil).count,
            digilocker_sessions_by_status: DigilockerSession.group(:status).count
          }
        end
      end
    end
  end
end
