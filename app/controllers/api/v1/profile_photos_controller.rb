module Api
  module V1
    class ProfilePhotosController < ApplicationController
      before_action :authenticate_user!

      def create_avatar
        file = params[:avatar]
        unless file.present?
          return render json: { error: "avatar file required" }, status: :unprocessable_content
        end

        current_user.avatar.attach(file)
        unless current_user.avatar.attached?
          return render json: { error: "Could not attach avatar" }, status: :unprocessable_content
        end

        # Keep gallery in sync: also store as first photo if empty.
        if current_user.photos.count.zero?
          current_user.photos.attach(current_user.avatar.blob)
        end

        render json: {
          user: UserSerializer.call(current_user, include_profile: true),
          profile_card: MemberCardSerializer.call(current_user)
        }
      end

      def create
        files = Array(params[:photos]).presence || Array(params[:photo]).presence
        files = files.compact
        if files.blank?
          return render json: { error: "photos required" }, status: :unprocessable_content
        end

        remaining = current_user.photo_slots_remaining
        if files.size > remaining
          return render json: {
            error: "Photo limit is #{User::MAX_PHOTOS}",
            details: [ "You can add #{remaining} more" ]
          }, status: :unprocessable_content
        end

        files.each { |f| current_user.photos.attach(f) }

        unless current_user.avatar.attached?
          current_user.avatar.attach(files.first)
        end

        render json: {
          user: UserSerializer.call(current_user, include_profile: true),
          profile_card: MemberCardSerializer.call(current_user)
        }
      end

      def destroy
        photo = current_user.photos.attachments.find_by(id: params[:id]) ||
                find_by_signed_id(params[:id])
        unless photo
          return render json: { error: "Not found" }, status: :not_found
        end

        was_avatar = current_user.avatar.attached? &&
                     current_user.avatar.blob_id == photo.blob_id
        photo.purge
        if was_avatar
          current_user.avatar.purge if current_user.avatar.attached?
          if current_user.photos.attached?
            current_user.avatar.attach(current_user.photos.first.blob)
          end
        end

        render json: {
          user: UserSerializer.call(current_user, include_profile: true),
          profile_card: MemberCardSerializer.call(current_user)
        }
      end

      def promote
        photo = current_user.photos.attachments.find_by(id: params[:id]) ||
                find_by_signed_id(params[:id])
        unless photo
          return render json: { error: "Not found" }, status: :not_found
        end

        current_user.avatar.attach(photo.blob)

        render json: {
          user: UserSerializer.call(current_user, include_profile: true),
          profile_card: MemberCardSerializer.call(current_user)
        }
      end

      private

      def find_by_signed_id(raw)
        blob = ActiveStorage::Blob.find_signed(raw)
        return nil unless blob

        current_user.photos.attachments.find_by(blob_id: blob.id)
      rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
