class MessageSerializer
  def self.call(message)
    {
      id: message.id,
      conversation_id: message.conversation_id,
      sender_id: message.sender_id,
      body: message.body,
      created_at: message.created_at,
      delivered_at: message.delivered_at,
      read_at: message.read_at,
      receipt: message.receipt_status
    }
  end
end
