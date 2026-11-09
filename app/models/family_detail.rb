class FamilyDetail < ApplicationRecord
  belongs_to :user

  FAMILY_TYPES = %w[joint nuclear].freeze
  FAMILY_VALUES = %w[traditional moderate liberal].freeze
  FAMILY_STATUSES = %w[middle_class upper_middle affluent rich].freeze

  validates :family_type, inclusion: { in: FAMILY_TYPES }, allow_nil: true
  validates :family_values, inclusion: { in: FAMILY_VALUES }, allow_nil: true
  validates :family_status, inclusion: { in: FAMILY_STATUSES }, allow_nil: true
  validates :brothers_count, :brothers_married, :sisters_count, :sisters_married,
            numericality: { greater_than_or_equal_to: 0 }

  def complete_for_step?
    family_type.present? && family_values.present?
  end
end
