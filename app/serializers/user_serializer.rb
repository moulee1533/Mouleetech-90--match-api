class UserSerializer
  def self.call(user, include_profile: false)
    card = MemberCardSerializer.call(user)
    payload = {
      id: user.id,
      email: user.email,
      phone: user.phone,
      full_name: user.full_name,
      status: user.status,
      signup_step: user.signup_step,
      profile_completed: user.profile_completed?,
      onboarding_required: user.onboarding_required?,
      digilocker_verified: user.digilocker_verified?,
      digilocker_verified_at: user.digilocker_verified_at,
      digilocker_id: user.masked_digilocker_id,
      verification_required: user.pending_verification?,
      created_at: user.created_at,
      updated_at: user.updated_at,
      avatar_url: card[:avatar_url],
      photo_urls: card[:photo_urls],
      age: card[:age],
      gender: card[:gender],
      city: card[:city],
      occupation: card[:occupation]
    }
    payload[:profile] = ProfileSerializer.call(user) if include_profile
    payload
  end
end
