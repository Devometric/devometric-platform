# frozen_string_literal: true

# Devometric Community Edition - Sample Data
# Run with: bin/rails db:seed
#
# This creates a demo organization with sample configuration
# to help you explore and develop Devometric locally.

puts ""
puts "============================================"
puts "  Devometric Community Edition"
puts "  Seeding sample data..."
puts "============================================"
puts ""

# Create demo organization
demo_org = Company.find_or_create_by!(slug: "demo-org") do |company|
  company.name = "Demo Organization"
  company.system_prompt = <<~PROMPT
    You are an AI productivity coach helping software engineers become more effective with AI-assisted development.

    Your role is to:
    1. Help developers use AI tools more effectively in their workflow
    2. Provide practical, actionable advice for coding, debugging, and code review
    3. Share best practices for prompting and working with AI assistants
    4. Guide developers on integrating AI into their development process

    Be concise, practical, and focused on immediate value. Use code examples when helpful.
    Adapt your responses to the developer's experience level and tech stack.
  PROMPT
  company.policies = <<~POLICIES
    ## Development Guidelines
    - Prioritize code quality and maintainability
    - Follow security best practices (OWASP Top 10)
    - Write clean, well-documented code
    - Use meaningful variable and function names
    - Keep functions small and focused
  POLICIES
  company.coding_standards = <<~STANDARDS
    ## Coding Standards
    - Use consistent formatting (Prettier/ESLint/RuboCop)
    - Write unit tests for business logic
    - Use meaningful commit messages (conventional commits)
    - Document public APIs and complex logic
    - Review code before merging
  STANDARDS
  company.work_culture = <<~CULTURE
    ## Team Values
    - Continuous learning and improvement
    - Collaboration and knowledge sharing
    - Constructive code reviews
    - Open communication
    - Work-life balance
  CULTURE
  company.tech_stack = ["Ruby on Rails", "PostgreSQL", "Redis", "Hotwire", "TailwindCSS"]
  company.settings = {
    "primary_color" => "#10b981",
    "position" => "bottom-right",
    "welcome_message" => "Hi! I'm your AI assistant. How can I help you become more productive with AI today?",
    "placeholder" => "Ask about AI tools, prompting techniques, or coding best practices..."
  }
end

puts "Created organization: #{demo_org.name}"
puts "  Slug: #{demo_org.slug}"
puts "  Embed Key: #{demo_org.embed_key}"

# Create admin user
admin = CompanyAdmin.find_or_create_by!(email: "admin@demo.com") do |a|
  a.company = demo_org
  a.name = "Demo Admin"
  a.password = "password123"
  a.password_confirmation = "password123"
  a.role = "owner"
end

puts ""
puts "Created admin user:"
puts "  Email: #{admin.email}"
puts "  Password: password123"

# Create community subscription (free tier)
subscription = Subscription.find_or_create_by!(company: demo_org) do |sub|
  sub.plan = "community"
  sub.status = "active"
  sub.current_period_start = Time.current
  sub.current_period_end = 100.years.from_now # Community edition doesn't expire
end

puts ""
puts "Subscription: #{subscription.plan} (#{subscription.status})"

# Create whitelisted domains for local development
dev_domains = ["localhost", "127.0.0.1", "0.0.0.0", "lvh.me"]
dev_domains.each do |domain|
  EmbedDomain.find_or_create_by!(company: demo_org, domain: domain) do |ed|
    ed.active = true
  end
end

puts ""
puts "Whitelisted domains for development:"
dev_domains.each { |d| puts "  - #{d}" }

# Create a sample chat session with example conversation
session = ChatSession.find_or_create_by!(
  company: demo_org,
  external_user_id: "demo-developer"
) do |s|
  s.locale = "en"
  s.user_context = {
    "role" => "Developer",
    "team" => "Platform",
    "experience_level" => "Mid-level"
  }
end

if session.messages.empty?
  Message.create!(
    chat_session: session,
    role: "user",
    content: "How can I use AI to help me write better code?"
  )

  Message.create!(
    chat_session: session,
    role: "assistant",
    content: <<~CONTENT
      Great question! Here are practical ways to use AI for better code:

      **1. Code Generation**
      Describe what you need in plain language:
      ```
      "Create a function that validates email addresses with proper error handling"
      ```

      **2. Code Review**
      Share your code and ask for improvements:
      ```
      "Review this function for bugs, performance issues, and readability"
      ```

      **3. Debugging**
      Paste error messages with context:
      ```
      "I'm getting this error: [error]. Here's my code: [code]. What's wrong?"
      ```

      **4. Learning**
      Ask for explanations:
      ```
      "Explain how async/await works in JavaScript with examples"
      ```

      **Tips for better AI interactions:**
      - Be specific about your tech stack and constraints
      - Provide context about what you've already tried
      - Ask follow-up questions to refine the response

      What area would you like to explore first?
    CONTENT
  )

  puts ""
  puts "Created sample chat session with example messages"
end

# Create sample usage logs for the dashboard charts
puts ""
puts "Creating sample usage data for charts..."
7.times do |i|
  date = Date.current - i.days
  UsageLog.find_or_create_by!(company: demo_org, date: date) do |log|
    log.sessions_count = rand(5..25)
    log.messages_count = rand(20..100)
    log.unique_users_count = rand(3..15)
    log.tokens_used = rand(10_000..50_000)
  end
end

puts ""
puts "============================================"
puts "  Setup Complete!"
puts "============================================"
puts ""
puts "Quick Start:"
puts "  1. Start the server:  bin/dev"
puts "  2. Open dashboard:    http://localhost:3000/admin"
puts "  3. Login with:        admin@demo.com / password123"
puts ""
puts "Test the widget:"
puts "  http://localhost:3000/test-widget.html"
puts ""
puts "Embed code for your pages:"
puts %(<script src="http://localhost:3000/widget.js" data-key="#{demo_org.embed_key}"></script>)
puts ""
puts "Configuration:"
puts "  - Edit config/settings.yml for app settings"
puts "  - Set LLM_PROVIDER env var (ollama, openai, anthropic)"
puts "  - See docs/self-hosted.md for deployment options"
puts ""
puts "Happy hacking!"
puts ""
