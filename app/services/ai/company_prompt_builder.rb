# frozen_string_literal: true

module AI
  class CompanyPromptBuilder
    DEFAULT_SYSTEM_PROMPT = <<~PROMPT
      You are an expert AI assistant helping software engineers become more AI-native in their development practices.

      Your role is to:
      1. Help developers use AI tools more effectively in their workflow
      2. Provide practical, actionable advice for coding, debugging, and code review
      3. Share best practices for prompting and working with AI assistants
      4. Guide developers on integrating AI into their development process

      Be concise, practical, and focused on immediate value. Use code examples when helpful.
    PROMPT

    def initialize(company)
      @company = company
    end

    def build_system_prompt
      parts = []

      parts << base_system_prompt
      parts << policies_section if @company.policies.present?
      parts << coding_standards_section if @company.coding_standards.present?
      parts << work_culture_section if @company.work_culture.present?
      parts << tech_stack_section if @company.tech_stack.present?

      parts.compact.join("\n\n")
    end

    def build_messages(chat_session, new_message_content)
      messages = []

      # Add conversation history
      chat_session.messages.ordered.each do |msg|
        messages << { role: msg.role, content: msg.content }
      end

      # Add the new user message
      messages << { role: "user", content: new_message_content }

      messages
    end

    def build_context_aware_prompt(user_context)
      context_parts = []

      if user_context["role"].present?
        context_parts << "The user's role is: #{user_context['role']}"
      end

      if user_context["team"].present?
        context_parts << "The user is on the #{user_context['team']} team"
      end

      if user_context["experience_level"].present?
        context_parts << "Their experience level is: #{user_context['experience_level']}"
      end

      return nil if context_parts.empty?

      "\n## User Context:\n#{context_parts.join("\n")}"
    end

    private

    def base_system_prompt
      @company.system_prompt.presence || DEFAULT_SYSTEM_PROMPT
    end

    def policies_section
      <<~SECTION
        ## Company Policies:
        #{@company.policies}
      SECTION
    end

    def coding_standards_section
      <<~SECTION
        ## Coding Standards:
        When providing code examples or reviewing code, follow these standards:
        #{@company.coding_standards}
      SECTION
    end

    def work_culture_section
      <<~SECTION
        ## Work Culture:
        Keep in mind the following aspects of our work culture:
        #{@company.work_culture}
      SECTION
    end

    def tech_stack_section
      return nil if @company.tech_stack.blank?

      tech = @company.tech_stack.is_a?(Array) ? @company.tech_stack.join(", ") : @company.tech_stack.to_s

      <<~SECTION
        ## Tech Stack:
        The company primarily uses: #{tech}
        Tailor your advice and examples to these technologies when relevant.
      SECTION
    end
  end
end
