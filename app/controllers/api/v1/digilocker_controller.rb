module Api
  module V1
    class DigilockerController < ApplicationController
      before_action :authenticate_user!, only: %i[status mock_verify]
      before_action :optional_authenticate, only: %i[authorize]

      def authorize
        user = resolve_authorize_user
        return render json: { error: "User not found" }, status: :not_found unless user

        if user.suspended?
          return render json: { error: "Account suspended" }, status: :forbidden
        end

        result = Digilocker::AuthorizeUrlBuilder.call(user: user)
        render json: {
          authorize_url: result.authorize_url,
          state: result.state
        }
      end

      def callback
        result = Digilocker::CallbackProcessor.call(
          code: params[:code],
          state: params[:state]
        )

        if json_response_requested?
          if result.success?
            return render json: {
              status: "ok",
              user: UserSerializer.call(result.user),
              access_token: issue_token(result.user),
              token_type: "Bearer",
              expires_in: JsonWebToken.expiry_seconds.to_i,
              verification_required: false
            }
          end

          return render json: { status: "error", reason: result.error }, status: :unprocessable_content
        end

        if result.success?
          redirect_to "#{Digilocker::Config.deep_link_success}?status=ok", allow_other_host: true
        else
          reason = ERB::Util.url_encode(result.error.to_s)
          redirect_to "#{Digilocker::Config.deep_link_failure}?reason=#{reason}", allow_other_host: true
        end
      end

      def status
        render json: {
          verified: current_user.digilocker_verified?,
          verified_at: current_user.digilocker_verified_at,
          digilocker_id: current_user.masked_digilocker_id,
          status: current_user.status
        }
      end

      # TEMP: hardcoded DigiLocker verify (no MeitY OAuth). Replace later with real client_id flow.
      # Accepts any digilocker_id + otp "123456".
      def mock_verify
        digilocker_id = params.require(:digilocker_id).to_s.strip
        otp = params.require(:otp).to_s.strip

        unless otp == "123456"
          return render json: { error: "Invalid DigiLocker OTP", details: [ "Use temporary OTP 123456" ] },
                        status: :unprocessable_content
        end

        if digilocker_id.blank?
          return render json: { error: "DigiLocker ID required" }, status: :unprocessable_content
        end

        subject = "hardcoded-#{digilocker_id}"
        conflict = User.where(digilocker_subject: subject).where.not(id: current_user.id).exists?
        if conflict
          return render json: { error: "DigiLocker identity already linked" }, status: :unprocessable_content
        end

        current_user.update!(
          digilocker_id: subject,
          digilocker_subject: subject,
          digilocker_verified_at: Time.current,
          digilocker_raw_profile: {
            "sub" => subject,
            "name" => current_user.full_name,
            "mode" => "hardcoded_temp"
          },
          status: "active"
        )
        current_user.sync_signup_step_after_digilocker!

        render json: {
          status: "ok",
          user: UserSerializer.call(current_user.reload, include_profile: true),
          access_token: issue_token(current_user),
          token_type: "Bearer",
          expires_in: JsonWebToken.expiry_seconds.to_i,
          verification_required: false
        }
      end

      private

      def optional_authenticate
        token = bearer_token
        return if token.blank?

        payload = JsonWebToken.decode(token)
        @current_user = payload && User.find_by(id: payload[:user_id], jti: payload[:jti])
      end

      def resolve_authorize_user
        return current_user if current_user

        if params[:user_id].present?
          return User.find_by(id: params[:user_id])
        end

        if params[:registration_token].present?
          payload = JsonWebToken.decode(params[:registration_token])
          return nil unless payload

          return User.find_by(id: payload[:user_id], jti: payload[:jti])
        end

        nil
      end

      def json_response_requested?
        params[:format].to_s == "json" || request.format.json?
      end
    end
  end
end
