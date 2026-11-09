module Api
  module V1
    class ConversationsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_active_user!

      def index
        list = current_user.conversations
                           .includes(:interest, :messages, conversation_participants: :user)
                           .order(Arel.sql("COALESCE(conversations.last_message_at, conversations.created_at) DESC"))
        render json: {
          conversations: list.map { |c| ConversationSerializer.call(c, viewer: current_user) }
        }
      end

      def messages
        conversation = current_user.conversations.find(params[:id])
        rows = conversation.messages.order(created_at: :asc).limit(200)
        render json: {
          conversation_id: conversation.id,
          messages: rows.map { |m| MessageSerializer.call(m) }
        }
      end

      def create_message
        conversation = current_user.conversations.find(params[:id])
        message = conversation.messages.build(
          sender: current_user,
          body: params.require(:body).to_s.strip
        )

        if message.save
          payload = MessageSerializer.call(message)
          ConversationChannel.broadcast_to(
            conversation,
            { type: "message.created", message: payload }
          )
          conversation.participants.each do |user|
            next if user.id == current_user.id

            InboxChannel.broadcast_to(
              user,
              {
                type: "message.created",
                message: payload,
                conversation: ConversationSerializer.call(conversation, viewer: user)
              }
            )
          end
          render json: { message: payload }, status: :created
        else
          render json: { error: "Validation failed", details: message.errors.full_messages },
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
