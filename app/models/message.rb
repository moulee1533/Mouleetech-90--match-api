class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { maximum: 4000 }

  after_create_commit :bump_conversation

  private

  def bump_conversation
    conversation.touch_last_message!
  end
end
