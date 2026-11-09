class MemberCardSerializer
  include Rails.application.routes.url_helpers

  def self.call(user)
    new.call(user)
  end

  def call(user)
    profile = user.member_profile
    location = user.location_detail
    career = user.career_detail
    family = user.family_detail
    dob = profile&.date_of_birth

    {
      id: user.id,
      full_name: user.full_name,
      age: age_from(dob),
      gender: profile&.gender,
      height_cm: profile&.height_cm,
      marital_status: profile&.marital_status,
      religion: profile&.religion,
      mother_tongue: profile&.mother_tongue,
      caste: profile&.caste,
      community: profile&.community,
      dosham: profile&.dosham,
      eating_habit: profile&.eating_habit,
      city: location&.city,
      state: location&.state,
      country: location&.country,
      occupation: career&.occupation,
      highest_education: career&.highest_education,
      annual_income_min: career&.annual_income_min,
      annual_income_max: career&.annual_income_max,
      family_type: family&.family_type,
      father_occupation: family&.father_occupation,
      brothers_count: family&.brothers_count,
      sisters_count: family&.sisters_count,
      digilocker_verified: user.digilocker_verified?,
      about_me: profile&.about_me,
      avatar_url: blob_url(user.primary_image),
      photo_urls: photo_urls_for(user),
      match_score: demo_match_score(user)
    }
  end

  private

  def age_from(dob)
    return nil if dob.blank?

    ((Time.zone.today - dob) / 365.25).floor
  end

  def blob_url(record)
    return nil if record.nil?
    return nil if record.respond_to?(:attached?) && !record.attached?

    opts = {
      only_path: false,
      host: ENV.fetch("APP_HOST", "127.0.0.1"),
      port: ENV.fetch("APP_PORT", "3000").to_i,
      protocol: ENV.fetch("APP_PROTOCOL", "http")
    }
    rails_blob_url(record, **opts)
  rescue StandardError => e
    Rails.logger.warn("blob_url failed: #{e.class}: #{e.message}")
    path = rails_blob_path(record, only_path: true)
    "http://#{ENV.fetch('APP_HOST', '127.0.0.1')}:#{ENV.fetch('APP_PORT', '3000')}#{path}"
  end

  def photo_urls_for(user)
    if user.photos.attached?
      return user.photos.filter_map { |photo| blob_url(photo) }
    end
    return [blob_url(user.avatar)].compact if user.avatar.attached?

    []
  end

  # Demo compatibility % until real engine ships (stable per user id).
  def demo_match_score(user)
    72 + (user.id.to_i % 24)
  end
end
