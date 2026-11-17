class Shortlist < ApplicationRecord
  belongs_to :user
  belongs_to :target_user, class_name: "User"

  validates :target_user_id, uniqueness: { scope: :user_id }
  validate :cannot_shortlist_self

  private

  def cannot_shortlist_self
    return if user_id.blank? || target_user_id.blank?
    return if user_id != target_user_id

    errors.add(:target_user_id, "cannot be yourself")
  end
end
