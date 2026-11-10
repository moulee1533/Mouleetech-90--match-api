module Api
  module V1
    class DeviceTokensController < ApplicationController
      before_action :authenticate_user!
      before_action :require_active_user!

      def create
        token = params.require(:token).to_s.strip
        platform = params[:platform].presence || "android"
        record = DeviceToken.find_or_initialize_by(token: token)
        record.user = current_user
        record.platform = platform
        if record.save
          render json: { ok: true }, status: :created
        else
          render json: { error: "Validation failed", details: record.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def destroy
        token = params.require(:token).to_s.strip
        DeviceToken.where(user: current_user, token: token).delete_all
        head :no_content
      end

      private

      def require_active_user!
        return if current_user.active?

        render json: { error: "Verification required" }, status: :forbidden
      end
    end
  end
end
