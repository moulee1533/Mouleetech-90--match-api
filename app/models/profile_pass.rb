class ProfilePass < ApplicationRecord
  belongs_to :user
  belongs_to :passed_user, class_name: "User"

  validates :passed_user_id, uniqueness: { scope: :user_id }
  validate :cannot_pass_self

  private

  def cannot_pass_self
    return if user_id.blank? || passed_user_id.blank?
    return if user_id != passed_user_id

    errors.add(:passed_user_id, "cannot be yourself")
  end
end
