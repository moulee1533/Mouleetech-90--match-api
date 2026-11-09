class ApplicationController < ActionController::API
  include Authenticable

  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_record_invalid(exception)
    render json: { error: "Validation failed", details: exception.record.errors.full_messages },
           status: :unprocessable_content
  end

  def render_not_found(_exception = nil)
    render json: { error: "Not found" }, status: :not_found
  end
end
