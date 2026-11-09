class Interest < ApplicationRecord
  STATUSES = %w[pending accepted declined].freeze

  belongs_to :from_user, class_name: "User"
  belongs_to :to_user, class_name: "User"
  has_one :conversation, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :to_user_id, uniqueness: { scope: :from_user_id }
  validate :cannot_interest_self
  validate :no_reverse_pending_conflict, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }

  def pending?
    status == "pending"
  end

  def accepted?
    status == "accepted"
  end

  def accept!
    raise ArgumentError, "Interest is not pending" unless pending?

    transaction do
      update!(status: "accepted")
      Conversation.open_for!(self)
    end
  end

  def decline!
    raise ArgumentError, "Interest is not pending" unless pending?

    update!(status: "declined")
  end

  private

  def cannot_interest_self
    errors.add(:to_user_id, "cannot be yourself") if from_user_id == to_user_id
  end

  def no_reverse_pending_conflict
    return if from_user_id.blank? || to_user_id.blank?

    reverse = Interest.find_by(from_user_id: to_user_id, to_user_id: from_user_id)
    return if reverse.nil?

    if reverse.pending?
      errors.add(:base, "They already sent you an interest — accept it in Inbox")
    elsif reverse.accepted?
      errors.add(:base, "You already have a mutual connection")
    end
  end
end
