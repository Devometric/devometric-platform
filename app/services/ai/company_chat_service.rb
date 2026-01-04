# frozen_string_literal: true

module AI
  class CompanyChatService
    class ChatError < StandardError; end

    def initialize(chat_session)
      @chat_session = chat_session
      @company = chat_session.company
      @prompt_builder = CompanyPromptBuilder.new(@company)
      @client = build_client
    end

    private

    def build_client
      # Use company's custom API key if available, otherwise use configured provider
      if @company.uses_own_api_key?
        # Company has their own Anthropic key
        AI::ClaudeClient.new(api_key: @company.effective_api_key)
      else
        # Use the configured LLM provider (supports Ollama, OpenAI, Anthropic)
        AI::LlmProvider.client
      end
    end

    public

    def send_message(content, stream: false, &block)
      # Create user message
      user_message = @chat_session.messages.create!(
        role: "user",
        content: content,
        tokens_used: 0
      )

      # Build the prompt
      system_prompt = build_full_system_prompt
      messages = @prompt_builder.build_messages(@chat_session, content)

      # Remove the last message since we just added it and it's included in messages
      messages.pop

      # Add user context if available
      if @chat_session.user_context.present?
        context_addition = @prompt_builder.build_context_aware_prompt(@chat_session.user_context)
        system_prompt = "#{system_prompt}#{context_addition}" if context_addition
      end

      if stream && block_given?
        stream_response(system_prompt, messages, content, &block)
      else
        sync_response(system_prompt, messages, content)
      end
    rescue AI::BaseClient::ApiError => e
      Rails.logger.error("Chat API error: #{e.message}")
      raise ChatError, "Failed to get AI response: #{e.message}"
    end

    private

    def build_full_system_prompt
      @prompt_builder.build_system_prompt
    end

    def sync_response(system_prompt, history_messages, new_content)
      messages = history_messages + [{ role: "user", content: new_content }]

      result = @client.chat(
        messages: messages,
        system: system_prompt
      )

      # Create assistant message
      assistant_message = @chat_session.messages.create!(
        role: "assistant",
        content: result[:content],
        tokens_used: result[:usage][:input_tokens] + result[:usage][:output_tokens]
      )

      {
        message: assistant_message,
        usage: result[:usage]
      }
    end

    def stream_response(system_prompt, history_messages, new_content, &block)
      messages = history_messages + [{ role: "user", content: new_content }]
      full_content = ""
      total_tokens = 0

      @client.chat(
        messages: messages,
        system: system_prompt,
        stream: true
      ) do |chunk, usage|
        if chunk
          full_content += chunk
          block.call(chunk, nil) if block_given?
        elsif usage
          total_tokens = usage[:input_tokens] + usage[:output_tokens]
          block.call(nil, usage) if block_given?
        end
      end

      # Create assistant message after streaming completes
      assistant_message = @chat_session.messages.create!(
        role: "assistant",
        content: full_content,
        tokens_used: total_tokens
      )

      {
        message: assistant_message,
        usage: { input_tokens: 0, output_tokens: total_tokens }
      }
    end
  end
end
