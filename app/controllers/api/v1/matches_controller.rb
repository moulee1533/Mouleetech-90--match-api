module Api
  module V1
    class MatchesController < ApplicationController
      before_action :authenticate_user!

      def index
        records, meta = MemberDirectory.matches_for(
          current_user,
          page: params[:page],
          per_page: params[:per_page] || 20
        )

        render json: {
          profiles: records.map { |u| MemberCardSerializer.call(u) },
          meta: meta
        }
      end
    end
  end
end
