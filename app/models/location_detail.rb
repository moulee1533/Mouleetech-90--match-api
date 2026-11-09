class LocationDetail < ApplicationRecord
  belongs_to :user

  RESIDENCY_STATUSES = %w[
    citizen permanent_resident work_permit student_visa temporary
  ].freeze

  validates :residency_status, inclusion: { in: RESIDENCY_STATUSES }, allow_nil: true

  def complete_for_step?
    country.present? && state.present? && city.present?
  end
end
