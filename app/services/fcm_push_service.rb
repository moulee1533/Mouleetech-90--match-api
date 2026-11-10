require "net/http"
require "json"
require "jwt"

# Sends FCM HTTP v1 notifications using a Firebase service-account JSON.
class FcmPushService
  SCOPE = "https://www.googleapis.com/auth/firebase.messaging".freeze

  def self.notify_new_message(recipient:, conversation:, message:, sender:)
    new.notify_new_message(
      recipient: recipient,
      conversation: conversation,
      message: message,
      sender: sender
    )
  end

  def notify_new_message(recipient:, conversation:, message:, sender:)
    tokens = recipient.device_tokens.pluck(:token)
    return if tokens.empty?

    project_id = credentials["project_id"]
    return if project_id.blank?

    access_token = oauth_access_token
    return if access_token.blank?

    tokens.each do |token|
      send_to_token(
        project_id: project_id,
        access_token: access_token,
        token: token,
        title: sender.full_name.presence || "New message",
        body: message.body.to_s.truncate(120),
        data: {
          type: "message.created",
          conversation_id: conversation.id.to_s,
          message_id: message.id.to_s,
          sender_id: sender.id.to_s
        }
      )
    end
  rescue StandardError => e
    Rails.logger.warn("[FCM] notify failed: #{e.class}: #{e.message}")
  end

  private

  def credentials
    @credentials ||= begin
      path = ENV["FIREBASE_CREDENTIALS_PATH"].presence ||
             Rails.root.join("config/credentials/firebase-adminsdk.json").to_s
      json = ENV["FIREBASE_CREDENTIALS_JSON"].presence
      raw = if path && File.exist?(path)
              File.read(path)
            elsif json
              json
            else
              "{}"
            end
      JSON.parse(raw)
    end
  end

  def oauth_access_token
    now = Time.now.to_i
    claim = {
      iss: credentials["client_email"],
      sub: credentials["client_email"],
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
      scope: SCOPE
    }
    assertion = JWT.encode(
      claim,
      OpenSSL::PKey::RSA.new(credentials["private_key"]),
      "RS256"
    )

    uri = URI("https://oauth2.googleapis.com/token")
    res = Net::HTTP.post_form(uri, {
      "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
      "assertion" => assertion
    })
    return nil unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)["access_token"]
  end

  def send_to_token(project_id:, access_token:, token:, title:, body:, data:)
    uri = URI("https://fcm.googleapis.com/v1/projects/#{project_id}/messages:send")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{access_token}"
    req["Content-Type"] = "application/json; charset=utf-8"
    req.body = {
      message: {
        token: token,
        notification: { title: title, body: body },
        data: data,
        android: {
          priority: "HIGH",
          notification: {
            channel_id: "chat_messages",
            sound: "default"
          }
        }
      }
    }.to_json

    res = http.request(req)
    if res.code.to_i == 404 || res.body.to_s.include?("UNREGISTERED")
      DeviceToken.where(token: token).delete_all
    elsif !res.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[FCM] send #{res.code}: #{res.body.to_s.truncate(300)}")
    end
  end
end
