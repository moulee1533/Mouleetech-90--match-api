module Api
  module V1
    module Admin
      class AuthController < ApplicationController
        include StaffAuthenticable

        def login
          username = params.require(:username).to_s.strip.downcase
          password = params.require(:password)

          staff = StaffUser.find_by(username: username)

          unless staff&.authenticate(password)
            return render json: { error: "Invalid username or password" }, status: :unauthorized
          end

          unless staff.active?
            return render json: { error: "Account inactive" }, status: :forbidden
          end

          render json: staff_token_response(staff)
        end

        def me
          authenticate_staff!
          return if performed?

          render json: { staff: StaffUserSerializer.call(current_staff) }
        end

        def logout
          authenticate_staff!
          return if performed?

          current_staff.rotate_jti!
          render json: { message: "Logged out" }
        end
      end
    end
  end
end
