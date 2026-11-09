module Api
  module V1
    class InterestsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_active_user!
      before_action :set_interest, only: %i[accept decline]

      def create
        to_user = User.find(params.require(:to_user_id))
        interest = current_user.sent_interests.build(
          to_user: to_user,
          note: params[:note],
          status: "pending"
        )

        if interest.save
          payload = InterestSerializer.call(interest, viewer: current_user)
          InboxChannel.broadcast_to(
            to_user,
            { type: "interest.created", interest: InterestSerializer.call(interest, viewer: to_user) }
          )
          render json: { interest: payload }, status: :created
        else
          render json: { error: "Validation failed", details: interest.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def received
        list = current_user.received_interests.includes(:from_user, :conversation).order(created_at: :desc)
        render json: {
          interests: list.map { |i| InterestSerializer.call(i, viewer: current_user) }
        }
      end

      def sent
        list = current_user.sent_interests.includes(:to_user, :conversation).order(created_at: :desc)
        render json: {
          interests: list.map { |i| InterestSerializer.call(i, viewer: current_user) }
        }
      end

      def accept
        unless @interest.to_user_id == current_user.id
          return render json: { error: "Forbidden" }, status: :forbidden
        end

        @interest.accept!
        conversation = @interest.conversation
        payload = InterestSerializer.call(@interest, viewer: current_user)

        InboxChannel.broadcast_to(
          @interest.from_user,
          {
            type: "interest.accepted",
            interest: InterestSerializer.call(@interest, viewer: @interest.from_user),
            conversation: ConversationSerializer.call(conversation, viewer: @interest.from_user)
          }
        )
        InboxChannel.broadcast_to(
          current_user,
          {
            type: "interest.accepted",
            interest: payload,
            conversation: ConversationSerializer.call(conversation, viewer: current_user)
          }
        )

        render json: {
          interest: payload,
          conversation: ConversationSerializer.call(conversation, viewer: current_user)
        }
      end

      def decline
        unless @interest.to_user_id == current_user.id
          return render json: { error: "Forbidden" }, status: :forbidden
        end

        @interest.decline!
        payload = InterestSerializer.call(@interest, viewer: current_user)
        InboxChannel.broadcast_to(
          @interest.from_user,
          { type: "interest.declined", interest: InterestSerializer.call(@interest, viewer: @interest.from_user) }
        )
        render json: { interest: payload }
      end

      private

      def set_interest
        @interest = Interest.find(params[:id])
      end

      def require_active_user!
        return if current_user.active?

        render json: { error: "Verification required" }, status: :forbidden
      end
    end
  end
end
