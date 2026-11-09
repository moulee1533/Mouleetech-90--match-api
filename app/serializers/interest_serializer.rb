class InterestSerializer
  def self.call(interest, viewer:)
    other = interest.from_user_id == viewer.id ? interest.to_user : interest.from_user
    {
      id: interest.id,
      status: interest.status,
      note: interest.note,
      direction: interest.from_user_id == viewer.id ? "sent" : "received",
      from_user_id: interest.from_user_id,
      to_user_id: interest.to_user_id,
      conversation_id: interest.conversation&.id,
      created_at: interest.created_at,
      updated_at: interest.updated_at,
      member: MemberCardSerializer.call(other)
    }
  end
end
