class ConversationSerializer
  def self.call(conversation, viewer:)
    other = conversation.other_user(viewer)
    last = conversation.messages.order(created_at: :desc).first
    {
      id: conversation.id,
      interest_id: conversation.interest_id,
      last_message_at: conversation.last_message_at,
      last_message: last && MessageSerializer.call(last),
      member: other && MemberCardSerializer.call(other),
      created_at: conversation.created_at
    }
  end
end
