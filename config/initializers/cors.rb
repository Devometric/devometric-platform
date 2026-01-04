# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"

    resource "/embed/*",
      headers: :any,
      methods: [:get, :post, :patch, :put, :delete, :options, :head],
      expose: ["X-Request-Id"]

    resource "/widget.js",
      headers: :any,
      methods: [:get, :options, :head]
  end
end
