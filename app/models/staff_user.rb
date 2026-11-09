class StaffUser < ApplicationRecord
  has_secure_password

  ROLES = %w[admin].freeze

  before_validation :normalize_username
  before_create :assign_jti

  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-zA-Z0-9._-]{3,64}\z/, message: "must be 3–64 chars (letters, numbers, . _ -)" }
  validates :full_name, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  def admin?
    role == "admin"
  end

  def rotate_jti!
    update!(jti: SecureRandom.uuid)
  end

  private

  def normalize_username
    self.username = username.to_s.strip.downcase.presence
  end

  def assign_jti
    self.jti ||= SecureRandom.uuid
  end
end
