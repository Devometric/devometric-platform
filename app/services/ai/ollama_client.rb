# frozen_string_literal: true

module AI
  class OllamaClient < BaseClient
    DEFAULT_MODEL = "llama3.2"
    DEFAULT_HOST = "http://localhost:11434"

    def initialize(model: nil, host: nil)
      @model = model || ENV.fetch("OLLAMA_MODEL", DEFAULT_MODEL)
      @host = host || ENV.fetch("OLLAMA_HOST", DEFAULT_HOST)
    end

    def chat(messages:, system: nil, max_tokens: DEFAULT_MAX_TOKENS, stream: false, &block)
      if stream && block_given?
        stream_chat(messages: messages, system: system, max_tokens: max_tokens, &block)
      else
        sync_chat(messages: messages, system: system, max_tokens: max_tokens)
      end
    end

    def available?
      response = connection.get("/api/tags")
      response.status == 200
    rescue Faraday::Error
      false
    end

    def provider_name
      "Ollama (#{@model})"
    end

    private

    def sync_chat(messages:, system:, max_tokens:)
      response = connection.post("/api/chat") do |req|
        req.body = build_body(messages: messages, system: system, stream: false).to_json
      end

      handle_response(response)
    end

    def stream_chat(messages:, system:, max_tokens:, &block)
      full_content = ""
      prompt_tokens = 0
      completion_tokens = 0

      connection.post("/api/chat") do |req|
        req.body = build_body(messages: messages, system: system, stream: true).to_json
        req.options.on_data = proc do |chunk, _|
          chunk.split("\n").each do |line|
            next if line.empty?

            begin
              data = JSON.parse(line)

              if data["message"] && data["message"]["content"]
                text = data["message"]["content"]
                full_content += text
                block.call(text, nil)
              end

              if data["done"]
                prompt_tokens = data["prompt_eval_count"] || 0
                completion_tokens = data["eval_count"] || 0
                block.call(nil, { input_tokens: prompt_tokens, output_tokens: completion_tokens })
              end
            rescue JSON::ParserError
              # Skip malformed JSON
            end
          end
        end
      end

      normalize_response(
        content: full_content,
        input_tokens: prompt_tokens,
        output_tokens: completion_tokens
      )
    end

    def build_body(messages:, system:, stream:)
      ollama_messages = []

      # Add system message if present
      if system.present?
        ollama_messages << { role: "system", content: system }
      end

      # Add conversation messages
      messages.each do |msg|
        ollama_messages << { role: msg[:role], content: msg[:content] }
      end

      {
        model: @model,
        messages: ollama_messages,
        stream: stream
      }
    end

    def connection
      @connection ||= Faraday.new(url: @host) do |f|
        f.headers["Content-Type"] = "application/json"
        f.options.timeout = 120
        f.options.open_timeout = 10
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      case response.status
      when 200
        parse_response(response.body)
      else
        error_message = begin
          JSON.parse(response.body)["error"] || "Unknown error"
        rescue JSON::ParserError
          response.body || "Unknown error"
        end
        raise ApiError, "Ollama API error: #{error_message}"
      end
    end

    def parse_response(body)
      data = body.is_a?(String) ? JSON.parse(body) : body
      content = data.dig("message", "content") || ""

      normalize_response(
        content: content,
        input_tokens: data["prompt_eval_count"] || 0,
        output_tokens: data["eval_count"] || 0
      )
    end
  end
end
