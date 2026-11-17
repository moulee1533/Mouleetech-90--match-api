class Report < ApplicationRecord
  REASONS = [
    "Spam",
    "Fake profile",
    "Inappropriate",
    "Harassment",
    "Other"
  ].freeze
  STATUSES = %w[open reviewed closed].freeze

  belongs_to :reporter, class_name: "User"
  belongs_to :reported_user, class_name: "User"

  validates :reason, presence: true, inclusion: { in: REASONS }
  validates :status, inclusion: { in: STATUSES }
  validates :reported_user_id, uniqueness: { scope: :reporter_id, message: "already reported" }
  validate :cannot_report_self

  private

  def cannot_report_self
    return if reporter_id.blank? || reported_user_id.blank?
    return if reporter_id != reported_user_id

    errors.add(:reported_user_id, "cannot be yourself")
  end
end
