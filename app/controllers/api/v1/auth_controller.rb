module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_user!, only: %i[me logout]

      def register
        attrs = register_params.to_h
        phone = User.normalize_phone_value(attrs["phone"] || attrs[:phone])
        attrs["phone"] = phone
        attrs["email"] = "#{phone}@phone.ninetiesmatch.local" if phone.present? && attrs["email"].blank?

        user = User.new(attrs.merge(status: "pending_verification", signup_step: "basic", profile_completed: false))

        if user.save
          render json: {
            user: UserSerializer.call(user),
            access_token: issue_token(user),
            token_type: "Bearer",
            expires_in: JsonWebToken.expiry_seconds.to_i,
            verification_required: true
          }, status: :created
        else
          render json: { error: "Validation failed", details: user.errors.full_messages },
                 status: :unprocessable_content
        end
      end

      def login
        phone = User.normalize_phone_value(params.require(:phone))
        user = User.find_by(phone: phone)

        unless user&.authenticate(params.require(:password))
          return render json: { error: "Invalid phone or password" }, status: :unauthorized
        end

        if user.suspended?
          return render json: { error: "Account suspended" }, status: :forbidden
        end

        render json: token_response(user)
      end

      def me
        render json: { user: UserSerializer.call(current_user, include_profile: true) }
      end

      def logout
        current_user.rotate_jti!
        render json: { message: "Logged out" }
      end

      private

      def register_params
        params.permit(:email, :password, :password_confirmation, :full_name, :phone)
      end
    end
  end
end
