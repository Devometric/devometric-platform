# frozen_string_literal: true

module AI
  class BaseClient
    class ApiError < StandardError; end
    class RateLimitError < ApiError; end
    class AuthenticationError < ApiError; end
    class ConfigurationError < ApiError; end

    DEFAULT_MAX_TOKENS = 4096

    def chat(messages:, system: nil, max_tokens: DEFAULT_MAX_TOKENS, stream: false, &block)
      raise NotImplementedError, "Subclasses must implement #chat"
    end

    def available?
      raise NotImplementedError, "Subclasses must implement #available?"
    end

    def provider_name
      raise NotImplementedError, "Subclasses must implement #provider_name"
    end

    protected

    def normalize_response(content:, input_tokens: 0, output_tokens: 0)
      {
        content: content,
        usage: {
          input_tokens: input_tokens,
          output_tokens: output_tokens
        }
      }
    end
  end
end
