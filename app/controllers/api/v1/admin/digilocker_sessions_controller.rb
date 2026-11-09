module Api
  module V1
    module Admin
      class DigilockerSessionsController < BaseController
        def index
          scope = DigilockerSession.includes(:user).order(created_at: :desc)
          scope = scope.where(status: params[:status]) if params[:status].present?

          page = [ params[:page].to_i, 1 ].max
          per_page = params[:per_page].to_i
          per_page = 20 if per_page <= 0
          per_page = [ per_page, 100 ].min

          total = scope.count
          sessions = scope.offset((page - 1) * per_page).limit(per_page)

          render json: {
            data: sessions.map { |s| session_json(s) },
            meta: { page: page, per_page: per_page, total: total }
          }
        end

        private

        def session_json(session)
          {
            id: session.id,
            user_id: session.user_id,
            user_email: session.user&.email,
            user_full_name: session.user&.full_name,
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
