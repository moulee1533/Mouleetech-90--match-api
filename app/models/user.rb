class User < ApplicationRecord
  has_secure_password

  STATUSES = %w[pending_verification active suspended].freeze
  SIGNUP_STEPS = %w[basic family work location partner digilocker done].freeze

  MAX_PHOTOS = 10

  has_many :digilocker_sessions, dependent: :destroy
  has_one :member_profile, dependent: :destroy
  has_one :family_detail, dependent: :destroy
  has_one :career_detail, dependent: :destroy
  has_one :location_detail, dependent: :destroy
  has_one :partner_preference, dependent: :destroy

  has_many :sent_interests, class_name: "Interest", foreign_key: :from_user_id, dependent: :destroy,
                            inverse_of: :from_user
  has_many :received_interests, class_name: "Interest", foreign_key: :to_user_id, dependent: :destroy,
                                inverse_of: :to_user
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :messages, foreign_key: :sender_id, dependent: :destroy, inverse_of: :sender

  has_one_attached :avatar
  has_many_attached :photos

  before_validation :normalize_email
  before_validation :normalize_phone
  before_validation :ensure_email_from_phone
  before_create :assign_jti
  before_create :assign_signup_defaults

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, uniqueness: true
  validates :full_name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :signup_step, inclusion: { in: SIGNUP_STEPS }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validate :password_complexity, if: -> { password.present? }
  validates :digilocker_id, uniqueness: true, allow_nil: true
  validates :digilocker_subject, uniqueness: true, allow_nil: true

  def pending_verification?
    status == "pending_verification"
  end

  def active?
    status == "active"
  end

  def suspended?
    status == "suspended"
  end

  def digilocker_verified?
    digilocker_verified_at.present?
  end

  def onboarding_required?
    !(profile_completed? && digilocker_verified?)
  end

  def advance_signup_step!(step)
    raise ArgumentError, "invalid step" unless SIGNUP_STEPS.include?(step)

    attrs = { signup_step: step }
    attrs[:profile_completed] = true if step == "digilocker" || step == "done"
    update!(attrs)
  end

  def sync_signup_step_after_digilocker!
    update!(signup_step: "done") if profile_completed? && digilocker_verified?
  end

  def rotate_jti!
    update!(jti: SecureRandom.uuid)
  end

  def masked_digilocker_id
    return nil if digilocker_id.blank?

    id = digilocker_id.to_s
    return "****" if id.length <= 4

    "#{'*' * (id.length - 4)}#{id[-4, 4]}"
  end

  def photo_slots_remaining
    MAX_PHOTOS - photos.count
  end

  def primary_image
    return avatar if avatar.attached?
    return photos.first if photos.attached?

    nil
  end

  def self.normalize_phone_value(raw)
    digits = raw.to_s.gsub(/\D/, "")
    return nil if digits.blank?

    digits = digits.sub(/\A91/, "") if digits.length > 10 && digits.start_with?("91")
    digits
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  def normalize_phone
    self.phone = self.class.normalize_phone_value(phone)
  end

  def ensure_email_from_phone
    return if email.present?
    return if phone.blank?

    self.email = "#{phone}@phone.ninetiesmatch.local"
  end

  def assign_jti
    self.jti ||= SecureRandom.uuid
  end

  def assign_signup_defaults
    self.signup_step ||= "basic"
    self.profile_completed = false if profile_completed.nil?
  end

  def password_complexity
    return if password.match?(/\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+\z/)

    errors.add(:password, "must include uppercase, lowercase, and a digit")
  end
end
