class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { maximum: 4000 }

  after_create_commit :bump_conversation

  def receipt_status
    return "read" if read_at.present?
    return "delivered" if delivered_at.present?

    "sent"
  end

  def mark_delivered!
    return if delivered_at.present? || read_at.present?

    update!(delivered_at: Time.current)
  end

  def mark_read!
    now = Time.current
    attrs = { read_at: now }
    attrs[:delivered_at] = now if delivered_at.blank?
    update!(attrs)
  end

  private

  def bump_conversation
    conversation.touch_last_message!
  end
end
