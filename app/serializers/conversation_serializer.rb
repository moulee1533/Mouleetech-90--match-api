class ConversationSerializer
  def self.call(conversation, viewer:)
    other = conversation.other_user(viewer)
    last = conversation.messages.order(created_at: :desc).first
    participant = conversation.conversation_participants.find { |p| p.user_id == viewer.id }
    last_read = participant&.last_read_at
    unread_scope = conversation.messages.where.not(sender_id: viewer.id)
    unread_scope = unread_scope.where("created_at > ?", last_read) if last_read.present?
    {
      id: conversation.id,
      interest_id: conversation.interest_id,
      last_message_at: conversation.last_message_at,
      last_message: last && MessageSerializer.call(last),
      member: other && MemberCardSerializer.call(other),
      unread_count: unread_scope.count,
      created_at: conversation.created_at
    }
  end
end
