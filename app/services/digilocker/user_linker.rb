module Digilocker
  class UserLinker
    Error = Class.new(StandardError)

    def self.call(user:, profile:)
      new(user:, profile:).call
    end

    def initialize(user:, profile:)
      @user = user
      @profile = profile
    end

    def call
      subject = @profile["sub"].presence
      raise Error, "DigiLocker subject missing" if subject.blank?

      conflict = User.where(digilocker_subject: subject).where.not(id: @user.id).exists? ||
                 User.where(digilocker_id: subject).where.not(id: @user.id).exists?
      raise Error, "DigiLocker identity already linked" if conflict

      @user.update!(
        digilocker_id: subject,
        digilocker_subject: subject,
        digilocker_verified_at: Time.current,
        digilocker_raw_profile: @profile,
        status: "active",
        full_name: @profile["name"].presence || @user.full_name
      )
      @user.sync_signup_step_after_digilocker!
      @user
    end
  end
end
