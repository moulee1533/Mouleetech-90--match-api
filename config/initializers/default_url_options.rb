# Blob URLs must match the Flutter API host (adb reverse → 127.0.0.1:3000).
Rails.application.routes.default_url_options.merge!(
  host: ENV.fetch("APP_HOST", "127.0.0.1"),
  port: ENV.fetch("APP_PORT", "3000").to_i,
  protocol: ENV.fetch("APP_PROTOCOL", "http")
)
