# frozen_string_literal: true

class HomeController < ApplicationController
  # Welcome page - developer hub for Community Edition
  def welcome
    @demo_company = Company.find_by(slug: "demo-org") || Company.first
  end

  # Demo page for testing the widget with a sample company
  def demo
    @demo_company = find_or_create_demo_company
  end

  private

  def find_or_create_demo_company
    Company.find_or_create_by!(slug: "demo") do |company|
      company.name = "Demo Organization"
      company.embed_key = SecureRandom.urlsafe_base64(32)
      company.system_prompt = demo_system_prompt
      company.policies = demo_policies
      company.coding_standards = demo_coding_standards
      company.work_culture = demo_work_culture
      company.tech_stack = %w[Ruby Rails JavaScript React PostgreSQL]
      company.settings = {
        "welcome_message" => "Hi! I'm your AI assistant. How can I help you become more productive with AI today?",
        "primary_color" => "#10B981",
        "placeholder" => "Ask about AI tools, prompting, or coding best practices..."
      }
    end.tap do |company|
      ensure_demo_subscription(company)
      ensure_demo_domain(company)
    end
  end

  def ensure_demo_subscription(company)
    company.subscription || company.create_subscription!(
      plan: "community",
      status: "active",
      current_period_start: Time.current,
      current_period_end: 100.years.from_now
    )
  end

  def ensure_demo_domain(company)
    %w[localhost 127.0.0.1 0.0.0.0 lvh.me].each do |domain|
      company.embed_domains.find_or_create_by!(domain: domain)
    end
  end

  def demo_system_prompt
    <<~PROMPT
      You are an AI productivity coach helping software engineers become more effective with AI-assisted development.

      Your role is to:
      1. Help developers use AI tools more effectively in their workflow
      2. Provide practical, actionable advice for coding, debugging, and code review
      3. Share best practices for prompting and working with AI assistants
      4. Guide developers on integrating AI into their development process

      ## Response Style:
      - Keep responses concise and practical
      - Use code examples when helpful
      - Be encouraging but honest
      - Adapt to the developer's experience level
    PROMPT
  end

  def demo_policies
    <<~POLICIES
      - Prioritize code quality and maintainability
      - Follow security best practices
      - Write clean, well-documented code
      - Review AI-generated code before committing
    POLICIES
  end

  def demo_coding_standards
    <<~STANDARDS
      - Use consistent formatting
      - Write unit tests for business logic
      - Use meaningful commit messages
      - Document public APIs
    STANDARDS
  end

  def demo_work_culture
    <<~CULTURE
      - Continuous learning and improvement
      - Collaboration and knowledge sharing
      - Open communication
      - Embrace AI as a collaborative tool
    CULTURE
  end
end
