# frozen_string_literal: true

module AI
  class OpenAIClient < BaseClient
    OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
    DEFAULT_MODEL = "gpt-4o"

    def initialize(api_key: nil, model: nil)
      @api_key = api_key || ENV.fetch("OPENAI_API_KEY", nil)
      @model = model || ENV.fetch("OPENAI_MODEL", DEFAULT_MODEL)
    end

    def chat(messages:, system: nil, max_tokens: DEFAULT_MAX_TOKENS, stream: false, &block)
      raise AuthenticationError, "OPENAI_API_KEY not configured" unless @api_key

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
      "OpenAI (#{@model})"
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
              delta = event.dig("choices", 0, "delta")

              if delta && delta["content"]
                text = delta["content"]
                full_content += text
                block.call(text, nil)
              end

              # Check for usage in final message
              if event["usage"]
                input_tokens = event["usage"]["prompt_tokens"] || 0
                output_tokens = event["usage"]["completion_tokens"] || 0
              end

              if event.dig("choices", 0, "finish_reason")
                block.call(nil, { input_tokens: input_tokens, output_tokens: output_tokens })
              end
            rescue JSON::ParserError
              # Skip malformed JSON
            end
          end
        end
      end

      normalize_response(
        content: full_content,
        input_tokens: input_tokens,
        output_tokens: output_tokens
      )
    end

    def build_body(messages:, system:, max_tokens:, stream: false)
      openai_messages = []

      # Add system message if present
      if system.present?
        openai_messages << { role: "system", content: system }
      end

      # Add conversation messages
      messages.each do |msg|
        openai_messages << { role: msg[:role], content: msg[:content] }
      end

      body = {
        model: @model,
        max_tokens: max_tokens,
        messages: openai_messages
      }
      body[:stream] = true if stream
      body[:stream_options] = { include_usage: true } if stream
      body.to_json
    end

    def connection
      @connection ||= Faraday.new(url: OPENAI_API_URL) do |f|
        f.request :json
        f.response :json
        f.headers["Content-Type"] = "application/json"
        f.headers["Authorization"] = "Bearer #{@api_key}"
        f.adapter Faraday.default_adapter
      end
    end

    def connection_for_streaming
      @connection_for_streaming ||= Faraday.new(url: OPENAI_API_URL) do |f|
        f.headers["Content-Type"] = "application/json"
        f.headers["Authorization"] = "Bearer #{@api_key}"
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
        raise ApiError, "OpenAI API error: #{error_message}"
      end
    end

    def parse_response(body)
      content = body.dig("choices", 0, "message", "content") || ""
      usage = body["usage"] || {}

      normalize_response(
        content: content,
        input_tokens: usage["prompt_tokens"] || 0,
        output_tokens: usage["completion_tokens"] || 0
      )
    end
  end
end
