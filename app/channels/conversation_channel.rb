class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = Conversation.find_by(id: params[:id])
    reject unless conversation&.participant?(current_user)

    stream_for conversation
  end
end
