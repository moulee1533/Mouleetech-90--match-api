class ProfileSerializer
  def self.call(user)
    {
      basic: serialize_basic(user.member_profile),
      family: serialize_family(user.family_detail),
      career: serialize_career(user.career_detail),
      location: serialize_location(user.location_detail),
      partner: serialize_partner(user.partner_preference)
    }
  end

  def self.serialize_basic(record)
    return nil unless record

    record.as_json(
      only: %w[
        gender date_of_birth height_cm marital_status religion mother_tongue
        caste sub_caste community gothra dosham eating_habit drinking_habit
        smoking_habit about_me profile_created_for
      ]
    )
  end

  def self.serialize_family(record)
    return nil unless record

    record.as_json(
      only: %w[
        family_type family_values family_status father_name father_occupation
        mother_name mother_occupation brothers_count brothers_married
        sisters_count sisters_married native_place about_family
      ]
    )
  end

  def self.serialize_career(record)
    return nil unless record

    record.as_json(
      only: %w[
        highest_education education_detail college_name employed_in occupation
        organization_name annual_income_min annual_income_max income_currency
      ]
    )
  end

  def self.serialize_location(record)
    return nil unless record

    record.as_json(
      only: %w[
        country state city citizenship residency_status willing_to_relocate
      ]
    )
  end

  def self.serialize_partner(record)
    return nil unless record

    record.as_json(
      only: %w[
        age_min age_max height_cm_min height_cm_max marital_statuses religions
        mother_tongues castes countries states cities educations occupations
        income_min about_partner
      ]
    )
  end
end
