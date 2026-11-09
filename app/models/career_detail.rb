class CareerDetail < ApplicationRecord
  belongs_to :user

  EMPLOYED_IN = %w[private government business self_employed not_working student].freeze

  validates :employed_in, inclusion: { in: EMPLOYED_IN }, allow_nil: true
  validates :annual_income_min, :annual_income_max,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :income_range_order

  def complete_for_step?
    highest_education.present? && employed_in.present?
  end

  private

  def income_range_order
    return if annual_income_min.blank? || annual_income_max.blank?
    return if annual_income_max >= annual_income_min

    errors.add(:annual_income_max, "must be greater than or equal to annual_income_min")
  end
end
