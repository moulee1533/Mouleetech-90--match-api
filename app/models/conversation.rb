class Conversation < ApplicationRecord
  belongs_to :interest
  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, dependent: :destroy

  def self.open_for!(interest)
    existing = find_by(interest: interest)
    return existing if existing

    create!(interest: interest) do |conversation|
      conversation.conversation_participants.build(user: interest.from_user)
      conversation.conversation_participants.build(user: interest.to_user)
    end
  end

  def participant?(user)
    conversation_participants.exists?(user_id: user.id)
  end

  def other_user(user)
    participants.find { |p| p.id != user.id }
  end

  def touch_last_message!
    update!(last_message_at: Time.current)
  end
end
