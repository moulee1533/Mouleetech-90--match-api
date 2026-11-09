# Demo matchmaking helpers — opposite-gender list + simple search filters.
class MemberDirectory
  def self.completed_scope
    User.where(profile_completed: true)
        .with_attached_avatar
        .with_attached_photos
        .includes(:member_profile, :location_detail, :career_detail, :family_detail)
  end

  def self.matches_for(current_user, page: 1, per_page: 20)
    scope = completed_scope.where.not(id: current_user.id)
    scope = apply_opposite_gender(scope, current_user)
    paginate(scope.order(id: :asc), page: page, per_page: per_page)
  end

  def self.search(current_user, filters = {})
    scope = completed_scope.where.not(id: current_user.id)
    scope = scope.joins(:member_profile)

    if filters[:gender].present?
      scope = scope.where(member_profiles: { gender: filters[:gender] })
    end

    if filters[:religion].present?
      scope = scope.where(member_profiles: { religion: filters[:religion] })
    end

    if filters[:city].present?
      scope = scope.left_joins(:location_detail)
                   .where("LOWER(location_details.city) = ?", filters[:city].to_s.downcase)
    end

    if filters[:age_min].present? || filters[:age_max].present?
      today = Time.zone.today
      if filters[:age_max].present?
        min_dob = today - filters[:age_max].to_i.years
        scope = scope.where("member_profiles.date_of_birth >= ?", min_dob)
      end
      if filters[:age_min].present?
        max_dob = today - filters[:age_min].to_i.years
        scope = scope.where("member_profiles.date_of_birth <= ?", max_dob)
      end
    end

    page = (filters[:page] || 1).to_i
    per_page = (filters[:per_page] || 20).to_i
    paginate(scope.order(id: :asc), page: page, per_page: per_page)
  end

  def self.preview_for(current_user, limit: 5)
    matches_for(current_user, page: 1, per_page: limit).first
  end

  def self.apply_opposite_gender(scope, current_user)
    gender = current_user.member_profile&.gender
    return scope if gender.blank?

    opposite = case gender
               when "male" then "female"
               when "female" then "male"
               else
                 return scope
               end

    scope.joins(:member_profile).where(member_profiles: { gender: opposite })
  end

  def self.paginate(scope, page:, per_page:)
    page = [ page.to_i, 1 ].max
    per_page = per_page.to_i.clamp(1, 50)
    total = scope.count
    records = scope.offset((page - 1) * per_page).limit(per_page).to_a
    [ records, { page: page, per_page: per_page, total: total, total_pages: (total.to_f / per_page).ceil } ]
  end
  private_class_method :paginate, :apply_opposite_gender
end
