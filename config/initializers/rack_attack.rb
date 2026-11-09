class Rack::Attack
  throttle("logins/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/login" && req.post?
  end

  throttle("logins/email", limit: 5, period: 1.minute) do |req|
    if req.path == "/api/v1/auth/login" && req.post?
      email = req.params["email"].to_s.downcase.strip
      email.presence
    end
  end

  throttle("digilocker/authorize/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/digilocker/authorize" && req.get?
  end

  throttle("register/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/register" && req.post?
  end
end

Rails.application.config.middleware.use Rack::Attack
