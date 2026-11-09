module Api
  module V1
    class ProfilesController < ApplicationController
      before_action :authenticate_user!

      def show
        render json: {
          user: UserSerializer.call(current_user, include_profile: true),
          profile: ProfileSerializer.call(current_user),
          profile_card: MemberCardSerializer.call(current_user)
        }
      end

      # Partial profile edit from the member Profile screen (post-onboarding).
      # Accepts any combination of account fields + nested sections; does not
      # advance signup_step or enforce onboarding step completeness.
      def update_profile
        errors = []

        ActiveRecord::Base.transaction do
          if account_params.present?
            current_user.assign_attributes(account_params)
            unless current_user.save
              errors.concat(current_user.errors.full_messages)
              raise ActiveRecord::Rollback
            end
          end

          {
            member_profile: nested_basic_params,
            family_detail: nested_family_params,
            career_detail: nested_career_params,
            location_detail: nested_location_params,
            partner_preference: nested_partner_params
          }.each do |association, attrs|
            next if attrs.blank?

            record = current_user.public_send(association) || current_user.public_send("build_#{association}")
            record.assign_attributes(attrs)
            unless record.save
              errors.concat(record.errors.full_messages)
              raise ActiveRecord::Rollback
            end
          end
        end

        if errors.any?
          return render json: { error: "Validation failed", details: errors },
                        status: :unprocessable_content
        end

        current_user.reload
        render json: {
          user: UserSerializer.call(current_user, include_profile: true),
          profile: ProfileSerializer.call(current_user),
          profile_card: MemberCardSerializer.call(current_user)
        }
      end

      def search
        records, meta = MemberDirectory.search(
          current_user,
          gender: params[:gender],
          age_min: params[:age_min],
          age_max: params[:age_max],
          city: params[:city],
          religion: params[:religion],
          page: params[:page],
          per_page: params[:per_page] || 20
        )

        render json: {
          profiles: records.map { |u| MemberCardSerializer.call(u) },
          meta: meta
        }
      end

      def public_show
        user = User.where(profile_completed: true)
                   .where.not(id: current_user.id)
                   .find(params[:id])

        render json: {
          profile: MemberCardSerializer.call(user),
          detail: ProfileSerializer.call(user),
          profile_card: MemberCardSerializer.call(user)
        }
      end

      def basic
        upsert_step(
          association: :member_profile,
          permitted: basic_params,
          next_step: "family",
          complete_check: ->(r) { r.complete_for_step? }
        )
      end

      def family
        upsert_step(
          association: :family_detail,
          permitted: family_params,
          next_step: "work",
          complete_check: ->(r) { r.complete_for_step? }
        )
      end

      def career
        upsert_step(
          association: :career_detail,
          permitted: career_params,
          next_step: "location",
          complete_check: ->(r) { r.complete_for_step? }
        )
      end

      def location
        upsert_step(
          association: :location_detail,
          permitted: location_params,
          next_step: "partner",
          complete_check: ->(r) { r.complete_for_step? }
        )
      end

      def partner
        upsert_step(
          association: :partner_preference,
          permitted: partner_params,
          next_step: "digilocker",
          complete_check: ->(r) { r.complete_for_step? },
          after_success: lambda {
            current_user.update!(profile_completed: true, signup_step: "digilocker")
            current_user.sync_signup_step_after_digilocker!
          }
        )
      end

      private

      def upsert_step(association:, permitted:, next_step:, complete_check:, after_success: nil)
        record = current_user.public_send(association) || current_user.public_send("build_#{association}")
        record.assign_attributes(permitted)

        unless complete_check.call(record)
          return render json: {
            error: "Validation failed",
            details: [ "Required fields for this step are incomplete" ]
          }, status: :unprocessable_content
        end

        if record.save
          unless after_success
            # Don't regress past digilocker/done when editing later
            unless %w[digilocker done].include?(current_user.signup_step)
              current_user.advance_signup_step!(next_step)
            end
          end
          after_success&.call
          current_user.reload

          render json: {
            user: UserSerializer.call(current_user, include_profile: true),
            profile: ProfileSerializer.call(current_user)
          }
        else
          render json: { error: "Validation failed", details: record.errors.full_messages },
                 status: :unprocessable_content
        end
      end

      def account_params
        params.permit(:full_name, :phone, :email)
      end

      def basic_params
        params.permit(
          :gender, :date_of_birth, :height_cm, :marital_status, :religion, :mother_tongue,
          :caste, :sub_caste, :community, :gothra, :dosham, :eating_habit, :drinking_habit,
          :smoking_habit, :about_me, :profile_created_for
        )
      end

      def family_params
        params.permit(
          :family_type, :family_values, :family_status, :father_name, :father_occupation,
          :mother_name, :mother_occupation, :brothers_count, :brothers_married,
          :sisters_count, :sisters_married, :native_place, :about_family
        )
      end

      def career_params
        params.permit(
          :highest_education, :education_detail, :college_name, :employed_in, :occupation,
          :organization_name, :annual_income_min, :annual_income_max, :income_currency
        )
      end

      def location_params
        params.permit(
          :country, :state, :city, :citizenship, :residency_status, :willing_to_relocate
        )
      end

      def partner_params
        params.permit(
          :age_min, :age_max, :height_cm_min, :height_cm_max, :income_min, :about_partner,
          marital_statuses: [], religions: [], mother_tongues: [], castes: [],
          countries: [], states: [], cities: [], educations: [], occupations: []
        )
      end

      def nested_basic_params
        return {} unless params[:basic].present?

        params.require(:basic).permit(
          :gender, :date_of_birth, :height_cm, :marital_status, :religion, :mother_tongue,
          :caste, :sub_caste, :community, :gothra, :dosham, :eating_habit, :drinking_habit,
          :smoking_habit, :about_me, :profile_created_for
        )
      end

      def nested_family_params
        return {} unless params[:family].present?

        params.require(:family).permit(
          :family_type, :family_values, :family_status, :father_name, :father_occupation,
          :mother_name, :mother_occupation, :brothers_count, :brothers_married,
          :sisters_count, :sisters_married, :native_place, :about_family
        )
      end

      def nested_career_params
        return {} unless params[:career].present?

        params.require(:career).permit(
          :highest_education, :education_detail, :college_name, :employed_in, :occupation,
          :organization_name, :annual_income_min, :annual_income_max, :income_currency
        )
      end

      def nested_location_params
        return {} unless params[:location].present?

        params.require(:location).permit(
          :country, :state, :city, :citizenship, :residency_status, :willing_to_relocate
        )
      end

      def nested_partner_params
        return {} unless params[:partner].present?

        params.require(:partner).permit(
          :age_min, :age_max, :height_cm_min, :height_cm_max, :income_min, :about_partner,
          marital_statuses: [], religions: [], mother_tongues: [], castes: [],
          countries: [], states: [], cities: [], educations: [], occupations: []
        )
      end
    end
  end
end
