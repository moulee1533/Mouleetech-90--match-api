class DigilockerSession < ApplicationRecord
  STATUSES = %w[started completed failed].freeze

  belongs_to :user

  validates :state, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :expires_at, presence: true

  scope :active, -> { where(status: "started").where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def mark_completed!
    update!(status: "completed", error_message: nil)
  end

  def mark_failed!(message)
    update!(status: "failed", error_message: message)
  end
end
