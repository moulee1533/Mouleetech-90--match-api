class PartnerPreference < ApplicationRecord
  belongs_to :user

  validates :age_min, :age_max, numericality: { greater_than_or_equal_to: 18, less_than_or_equal_to: 80 },
                                allow_nil: true
  validate :age_range_order

  def complete_for_step?
    age_min.present? && age_max.present?
  end

  private

  def age_range_order
    return if age_min.blank? || age_max.blank?
    return if age_max >= age_min

    errors.add(:age_max, "must be greater than or equal to age_min")
  end
end
