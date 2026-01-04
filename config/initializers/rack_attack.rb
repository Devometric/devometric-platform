# frozen_string_literal: true

class Rack::Attack
  ### Configure Cache ###
  # Uses Rails.cache by default, which is solid_cache in production

  ### Throttle Rules ###

  # Demo page - limit to 3 requests per IP per hour
  # Prevents abuse of the demo feature
  throttle("demo/ip", limit: 3, period: 1.hour) do |req|
    req.ip if req.path == "/demo" && req.get?
  end

  # Widget initialization - limit to 5 sessions per IP per hour
  throttle("embed/init/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/embed/v1/init" && req.post?
  end

  # Message creation - limit to 30 messages per IP per hour
  # This protects against LLM API abuse (expensive calls)
  throttle("embed/messages/ip", limit: 30, period: 1.hour) do |req|
    req.ip if req.path.match?(%r{/embed/v1/sessions/.+/messages}) && req.post?
  end

  # Waitlist submissions - limit to 3 per IP per day
  throttle("waitlist/ip", limit: 3, period: 1.day) do |req|
    req.ip if req.path == "/waitlist" && req.post?
  end

  ### Custom Responses ###

  # Return JSON for API endpoints, HTML for regular pages
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = Time.current
    retry_after = (match_data[:period] - (now.to_i % match_data[:period])).to_i

    if request.path.start_with?("/embed/", "/admin/")
      # JSON response for API endpoints
      [
        429,
        {
          "Content-Type" => "application/json",
          "Retry-After" => retry_after.to_s
        },
        [{
          error: "Rate limit exceeded",
          message: "You've reached the demo usage limit. Please try again later.",
          retry_after: retry_after
        }.to_json]
      ]
    else
      # HTML response for web pages
      [
        429,
        {
          "Content-Type" => "text/html",
          "Retry-After" => retry_after.to_s
        },
        ["<html><body><h1>Rate Limit Exceeded</h1><p>You've reached the demo usage limit. Please try again in #{retry_after / 60} minutes.</p></body></html>"]
      ]
    end
  end

  ### Safelist ###

  # Allow all requests from localhost in development
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1" if Rails.env.development?
  end
end
