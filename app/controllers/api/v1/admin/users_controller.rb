module Api
  module V1
    module Admin
      class UsersController < BaseController
        def index
          scope = User.order(created_at: :desc)
          scope = scope.where(status: params[:status]) if params[:status].present?

          if params[:q].present?
            q = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
            scope = scope.where(
              "email ILIKE :q OR full_name ILIKE :q OR COALESCE(phone, '') ILIKE :q",
              q: q
            )
          end

          page = [ params[:page].to_i, 1 ].max
          per_page = params[:per_page].to_i
          per_page = 20 if per_page <= 0
          per_page = [ per_page, 100 ].min

          total = scope.count
          users = scope
            .with_attached_avatar
            .with_attached_photos
            .includes(:member_profile, :location_detail, :career_detail)
            .offset((page - 1) * per_page)
            .limit(per_page)

          render json: {
            data: users.map { |u| UserSerializer.call(u) },
            meta: { page: page, per_page: per_page, total: total }
          }
        end

        def show
          user = User
            .with_attached_avatar
            .with_attached_photos
            .includes(
              :member_profile,
              :family_detail,
              :career_detail,
              :location_detail,
              :partner_preference
            )
            .find(params[:id])
          sessions = user.digilocker_sessions.order(created_at: :desc).limit(50)

          render json: {
            user: UserSerializer.call(user, include_profile: true),
            profile: ProfileSerializer.call(user),
            digilocker_sessions: sessions.map { |s| digilocker_session_json(s) }
          }
        end

        private

        def digilocker_session_json(session)
          {
            id: session.id,
            user_id: session.user_id,
            state: session.state,
            status: session.status,
            expires_at: session.expires_at,
            error_message: session.error_message,
            created_at: session.created_at,
            updated_at: session.updated_at
          }
        end
      end
    end
  end
end
