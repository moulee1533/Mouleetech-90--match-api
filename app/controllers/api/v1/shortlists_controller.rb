module Api
  module V1
    class ShortlistsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_active_user!

      def index
        ids = current_user.shortlists.order(created_at: :desc).pluck(:target_user_id)
        users = MemberDirectory.completed_scope.where(id: ids).index_by(&:id)
        profiles = ids.filter_map { |id| users[id] }.map { |u| MemberCardSerializer.call(u, viewer: current_user) }
        render json: { shortlist_ids: ids, profiles: profiles }
      end

      def create
        target = User.find(params.require(:target_user_id))
        record = current_user.shortlists.find_or_initialize_by(target_user: target)
        if record.persisted? || record.save
          render json: { shortlisted: true, target_user_id: target.id }, status: :created
        else
          render json: { error: "Validation failed", details: record.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def destroy
        target_id = params[:target_user_id].presence || params[:id]
        current_user.shortlists.where(target_user_id: target_id).delete_all
        render json: { shortlisted: false, target_user_id: target_id.to_i }
      end

      private

      def require_active_user!
        return if current_user.active?

        render json: { error: "Verification required" }, status: :forbidden
      end
    end
  end
end
