module Api
  module V1
    class ProfilePassesController < ApplicationController
      before_action :authenticate_user!
      before_action :require_active_user!

      def create
        passed = User.find(params.require(:passed_user_id))
        record = current_user.profile_passes.find_or_initialize_by(passed_user: passed)
        if record.persisted? || record.save
          # Passing also removes shortlist for that person.
          current_user.shortlists.where(target_user_id: passed.id).delete_all
          render json: { passed: true, passed_user_id: passed.id }, status: :created
        else
          render json: { error: "Validation failed", details: record.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def destroy
        passed_id = params[:passed_user_id].presence || params[:id]
        current_user.profile_passes.where(passed_user_id: passed_id).delete_all
        render json: { passed: false, passed_user_id: passed_id.to_i }
      end

      private

      def require_active_user!
        return if current_user.active?

        render json: { error: "Verification required" }, status: :forbidden
      end
    end
  end
end
