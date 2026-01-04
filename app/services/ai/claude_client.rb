# frozen_string_literal: true

module AI
  class ClaudeClient < BaseClient
    CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
    DEFAULT_MODEL = "claude-sonnet-4-20250514"

    def initialize(api_key: nil, model: nil)
      @api_key = api_key || ENV.fetch("ANTHROPIC_API_KEY", nil)
      @model = model || ENV.fetch("ANTHROPIC_MODEL", DEFAULT_MODEL)
    end

    def chat(messages:, system: nil, max_tokens: DEFAULT_MAX_TOKENS, stream: false, &block)
      raise AuthenticationError, "ANTHROPIC_API_KEY not configured" unless @api_key

      if stream && block_given?
        stream_chat(messages: messages, system: system, max_tokens: max_tokens, &block)
      else
        sync_chat(messages: messages, system: system, max_tokens: max_tokens)
      end
    end

    def available?
      @api_key.present?
    end

    def provider_name
      "Anthropic (#{@model})"
    end

    private

    def sync_chat(messages:, system:, max_tokens:)
      response = connection.post do |req|
        req.body = build_body(messages: messages, system: system, max_tokens: max_tokens)
      end

      handle_response(response)
    end

    def stream_chat(messages:, system:, max_tokens:, &block)
      buffer = ""
      full_content = ""
      input_tokens = 0
      output_tokens = 0

      connection_for_streaming.post do |req|
        req.body = build_body(messages: messages, system: system, max_tokens: max_tokens, stream: true)
        req.options.on_data = proc do |chunk, _|
          buffer += chunk
          while (line_end = buffer.index("\n"))
            line = buffer[0...line_end]
            buffer = buffer[(line_end + 1)..]

            next if line.empty? || !line.start_with?("data: ")

            data = line[6..]
            next if data == "[DONE]"

            begin
              event = JSON.parse(data)
              case event["type"]
              when "content_block_delta"
                text = event.dig("delta", "text")
                if text
                  full_content += text
                  block.call(text, nil)
                end
              when "message_start"
                input_tokens = event.dig("message", "usage", "input_tokens") || 0
              when "message_delta"
                output_tokens = event.dig("usage", "output_tokens") || 0
              when "message_stop"
                block.call(nil, { input_tokens: input_tokens, output_tokens: output_tokens })
              when "error"
                raise ApiError, event.dig("error", "message") || "Unknown streaming error"
              end
            rescue JSON::ParserError
              # Skip malformed JSON
            end
          end
        end
      end

      { content: full_content, usage: { input_tokens: input_tokens, output_tokens: output_tokens } }
    end

    def build_body(messages:, system:, max_tokens:, stream: false)
      body = {
        model: @model,
        max_tokens: max_tokens,
        messages: messages.map { |m| { role: m[:role], content: m[:content] } }
      }
      body[:system] = system if system.present?
      body[:stream] = true if stream
      body.to_json
    end

    def connection
      @connection ||= Faraday.new(url: CLAUDE_API_URL) do |f|
        f.request :json
        f.response :json
        f.headers["Content-Type"] = "application/json"
        f.headers["x-api-key"] = @api_key
        f.headers["anthropic-version"] = "2023-06-01"
        f.adapter Faraday.default_adapter
      end
    end

    def connection_for_streaming
      @connection_for_streaming ||= Faraday.new(url: CLAUDE_API_URL) do |f|
        f.headers["Content-Type"] = "application/json"
        f.headers["x-api-key"] = @api_key
        f.headers["anthropic-version"] = "2023-06-01"
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      case response.status
      when 200
        parse_response(response.body)
      when 401
        raise AuthenticationError, "Invalid API key"
      when 429
        raise RateLimitError, "Rate limit exceeded"
      else
        error_message = response.body.dig("error", "message") || "Unknown error"
        raise ApiError, "Claude API error: #{error_message}"
      end
    end

    def parse_response(body)
      content = body.dig("content", 0, "text") || ""
      usage = body["usage"] || {}

      {
        content: content,
        usage: {
          input_tokens: usage["input_tokens"] || 0,
          output_tokens: usage["output_tokens"] || 0
        }
      }
    end
  end
end
