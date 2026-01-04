# frozen_string_literal: true

module AI
  class LlmProvider
    PROVIDERS = {
      "ollama" => :ollama,
      "openai" => :openai,
      "anthropic" => :anthropic,
      "claude" => :anthropic
    }.freeze

    class << self
      def client(provider: nil, **options)
        provider_name = (provider || default_provider).to_s.downcase

        case PROVIDERS[provider_name]
        when :ollama
          OllamaClient.new(**ollama_options(options))
        when :openai
          OpenAIClient.new(**openai_options(options))
        when :anthropic
          ClaudeClient.new(**anthropic_options(options))
        else
          raise BaseClient::ConfigurationError, "Unknown LLM provider: #{provider_name}. " \
            "Supported providers: #{PROVIDERS.keys.join(', ')}"
        end
      end

      def default_provider
        ENV.fetch("LLM_PROVIDER", "ollama")
      end

      def available_providers
        available = []

        # Check Ollama
        if ENV["OLLAMA_HOST"].present? || ollama_localhost_available?
          available << { name: "ollama", model: ENV.fetch("OLLAMA_MODEL", "llama3.2") }
        end

        # Check OpenAI
        if ENV["OPENAI_API_KEY"].present?
          available << { name: "openai", model: ENV.fetch("OPENAI_MODEL", "gpt-4o") }
        end

        # Check Anthropic
        if ENV["ANTHROPIC_API_KEY"].present?
          available << { name: "anthropic", model: ENV.fetch("ANTHROPIC_MODEL", "claude-sonnet-4-20250514") }
        end

        available
      end

      private

      def ollama_options(options)
        {
          model: options[:model] || ENV["OLLAMA_MODEL"],
          host: options[:host] || ENV["OLLAMA_HOST"]
        }.compact
      end

      def openai_options(options)
        {
          api_key: options[:api_key] || ENV["OPENAI_API_KEY"],
          model: options[:model] || ENV["OPENAI_MODEL"]
        }.compact
      end

      def anthropic_options(options)
        {
          api_key: options[:api_key] || ENV["ANTHROPIC_API_KEY"]
        }.compact
      end

      def ollama_localhost_available?
        client = OllamaClient.new
        client.available?
      rescue StandardError
        false
      end
    end
  end
end
