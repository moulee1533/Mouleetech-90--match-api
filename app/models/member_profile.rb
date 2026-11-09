class MemberProfile < ApplicationRecord
  belongs_to :user

  GENDERS = %w[male female other].freeze
  MARITAL_STATUSES = %w[never_married divorced widowed awaiting_divorce].freeze
  PROFILE_CREATED_FOR = %w[self son daughter sibling relative friend].freeze
  HABITS = %w[never occasionally yes no vegetarian eggetarian non_vegetarian].freeze

  validates :gender, inclusion: { in: GENDERS }, allow_nil: true
  validates :marital_status, inclusion: { in: MARITAL_STATUSES }, allow_nil: true
  validates :profile_created_for, inclusion: { in: PROFILE_CREATED_FOR }
  validates :height_cm, numericality: { greater_than: 90, less_than: 250 }, allow_nil: true
  validate :date_of_birth_reasonable

  def complete_for_step?
    gender.present? && date_of_birth.present? && height_cm.present? &&
      marital_status.present? && religion.present? && mother_tongue.present?
  end

  private

  def date_of_birth_reasonable
    return if date_of_birth.blank?

    age = ((Time.zone.today - date_of_birth) / 365.25).floor
    errors.add(:date_of_birth, "must yield age between 18 and 80") unless age.between?(18, 80)
  end
end
