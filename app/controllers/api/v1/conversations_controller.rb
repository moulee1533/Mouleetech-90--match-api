module Api
  module V1
    class ConversationsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_active_user!
      before_action :set_conversation, only: %i[messages create_message delivered read]

      def index
        list = current_user.conversations
                           .includes(:interest, :messages, conversation_participants: :user)
                           .order(Arel.sql("COALESCE(conversations.last_message_at, conversations.created_at) DESC"))
        render json: {
          conversations: list.map { |c| ConversationSerializer.call(c, viewer: current_user) }
        }
      end

      def messages
        rows = @conversation.messages.order(created_at: :asc).limit(200)
        render json: {
          conversation_id: @conversation.id,
          messages: rows.map { |m| MessageSerializer.call(m) }
        }
      end

      def create_message
        message = @conversation.messages.build(
          sender: current_user,
          body: params.require(:body).to_s.strip
        )

        if message.save
          payload = MessageSerializer.call(message)
          ConversationChannel.broadcast_to(
            @conversation,
            { type: "message.created", message: payload }
          )
          @conversation.participants.each do |user|
            next if user.id == current_user.id

            InboxChannel.broadcast_to(
              user,
              {
                type: "message.created",
                message: payload,
                conversation: ConversationSerializer.call(@conversation, viewer: user)
              }
            )
            FcmPushService.notify_new_message(
              recipient: user,
              conversation: @conversation,
              message: message,
              sender: current_user
            )
          end
          render json: { message: payload }, status: :created
        else
          render json: { error: "Validation failed", details: message.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def delivered
        updated = @conversation.messages
                               .where.not(sender_id: current_user.id)
                               .where(delivered_at: nil, read_at: nil)
                               .to_a
        updated.each(&:mark_delivered!)
        broadcast_receipts(updated)
        render json: {
          messages: updated.map { |m| MessageSerializer.call(m) }
        }
      end

      def read
        updated = @conversation.messages
                               .where.not(sender_id: current_user.id)
                               .where(read_at: nil)
                               .to_a
        updated.each(&:mark_read!)
        participant = @conversation.conversation_participants.find_by!(user: current_user)
        participant.update!(last_read_at: Time.current)
        broadcast_receipts(updated)
        render json: {
          messages: updated.map { |m| MessageSerializer.call(m) }
        }
      end

      private

      def set_conversation
        @conversation = current_user.conversations.find(params[:id])
      end

      def broadcast_receipts(messages)
        messages.each do |message|
          payload = MessageSerializer.call(message)
          ConversationChannel.broadcast_to(
            @conversation,
            { type: "message.receipt", message: payload }
          )
          # Also notify sender via inbox stream so hearts update outside the chat.
          InboxChannel.broadcast_to(
            message.sender,
            { type: "message.receipt", message: payload }
          )
        end
      end

      def require_active_user!
        return if current_user.active?

        render json: { error: "Verification required" }, status: :forbidden
      end
    end
  end
end
