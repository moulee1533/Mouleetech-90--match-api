module Api
  module V1
    class ReportsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_active_user!

      def create
        reported = User.find(params.require(:reported_user_id))
        report = current_user.reports_filed.build(
          reported_user: reported,
          reason: params.require(:reason).to_s,
          details: params[:details].presence
        )

        if report.save
          render json: {
            report: {
              id: report.id,
              reported_user_id: report.reported_user_id,
              reason: report.reason,
              details: report.details,
              status: report.status,
              created_at: report.created_at
            }
          }, status: :created
        else
          render json: { error: "Validation failed", details: report.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      private

      def require_active_user!
        return if current_user.active?

        render json: { error: "Verification required" }, status: :forbidden
      end
    end
  end
end
