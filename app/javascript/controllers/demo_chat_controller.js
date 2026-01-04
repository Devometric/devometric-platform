import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "sendButton", "role", "experience", "aiExperience"]
  static values = { embedKey: String }

  connect() {
    console.log("Demo chat controller connected")
    console.log("Embed key:", this.embedKeyValue)
    this.sessionToken = null
    this.userContext = {}
    this.messageCount = 0
  }

  async submitOnboarding(event) {
    event.preventDefault()
    console.log("Onboarding form submitted")

    const role = this.roleTarget.value
    const experience = this.experienceTarget.value
    const aiExperience = this.aiExperienceTarget.value

    console.log("Form values:", { role, experience, aiExperience })

    if (!role || !experience || !aiExperience) {
      alert("Please fill in all fields")
      return
    }

    this.userContext = { role, experience, ai_experience: aiExperience }

    // Initialize session with user context
    try {
      console.log("Initializing session...")
      const response = await fetch("/embed/v1/init", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Embed-Key": this.embedKeyValue
        },
        body: JSON.stringify({
          user_context: this.userContext,
          external_user_id: `demo-${Date.now()}`
        })
      })

      console.log("Response status:", response.status)

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        console.error("Session init failed:", errorData)
        throw new Error(errorData.error || "Failed to initialize session")
      }

      const data = await response.json()
      console.log("Session created:", data)
      this.sessionToken = data.session_token

      // Update UI
      this.showOnboardingComplete()
      this.enableChat()

      // Send initial context message to AI
      this.sendContextMessage()

    } catch (error) {
      console.error("Onboarding error:", error)
      alert(`Failed to start session: ${error.message}`)
    }
  }

  showOnboardingComplete() {
    document.getElementById("onboarding-form").classList.add("hidden")
    document.getElementById("onboarding-complete").classList.remove("hidden")

    const roleLabels = {
      frontend: "Frontend Developer",
      backend: "Backend Developer",
      fullstack: "Full Stack Developer",
      devops: "DevOps Engineer",
      data: "Data Engineer/Scientist",
      lead: "Tech Lead/Manager",
      other: "Developer"
    }

    const expLabels = {
      junior: "Junior",
      mid: "Mid-level",
      senior: "Senior",
      staff: "Staff+"
    }

    const aiLabels = {
      none: "No AI experience",
      beginner: "AI Beginner",
      regular: "Occasional AI user",
      daily: "Daily AI user",
      expert: "AI Power user"
    }

    document.getElementById("user-profile").innerHTML = `
      <p><strong>Role:</strong> ${roleLabels[this.userContext.role]}</p>
      <p><strong>Experience:</strong> ${expLabels[this.userContext.experience]}</p>
      <p><strong>AI Skills:</strong> ${aiLabels[this.userContext.ai_experience]}</p>
    `

    // Show initial score based on AI experience
    this.showInitialScore()
  }

  showInitialScore() {
    const scoreCard = document.getElementById("score-card")
    scoreCard.classList.remove("hidden")

    const scores = {
      none: { score: 15, label: "Just Starting" },
      beginner: { score: 30, label: "Beginner" },
      regular: { score: 50, label: "Developing" },
      daily: { score: 70, label: "Proficient" },
      expert: { score: 90, label: "Expert" }
    }

    const { score, label } = scores[this.userContext.ai_experience]

    document.getElementById("score-value").textContent = score
    document.getElementById("score-label").textContent = label

    setTimeout(() => {
      document.getElementById("score-bar").style.width = `${score}%`
    }, 100)

    // Show initial recommendations
    this.showRecommendations()
  }

  showRecommendations() {
    const recsCard = document.getElementById("recommendations-card")
    recsCard.classList.remove("hidden")

    const recommendations = this.getRecommendations()
    const recsList = document.getElementById("recommendations-list")

    recsList.innerHTML = recommendations.map((rec, i) => `
      <div class="flex items-start gap-3 p-3 bg-gray-900/50 rounded-lg">
        <span class="w-6 h-6 bg-emerald-500/20 text-emerald-400 rounded-full flex items-center justify-center text-sm font-medium flex-shrink-0">${i + 1}</span>
        <div>
          <p class="font-medium text-sm">${rec.title}</p>
          <p class="text-xs text-gray-400 mt-1">${rec.description}</p>
        </div>
      </div>
    `).join("")
  }

  getRecommendations() {
    const aiExp = this.userContext.ai_experience
    const role = this.userContext.role

    const baseRecs = {
      none: [
        { title: "Start with GitHub Copilot", description: "The easiest way to get started with AI-assisted coding" },
        { title: "Try ChatGPT for code explanations", description: "Paste code and ask for explanations to learn" },
        { title: "Learn basic prompting", description: "Start with simple, clear instructions" }
      ],
      beginner: [
        { title: "Practice prompt engineering", description: "Learn to write specific, context-rich prompts" },
        { title: "Use AI for code reviews", description: "Have AI review your code before committing" },
        { title: "Experiment with different AI tools", description: "Try Claude, ChatGPT, and Copilot to find your preference" }
      ],
      regular: [
        { title: "Integrate AI into your workflow", description: "Make AI a default part of your development process" },
        { title: "Use AI for documentation", description: "Generate docs, comments, and README files" },
        { title: "Learn advanced prompting techniques", description: "Chain-of-thought, few-shot examples, role prompts" }
      ],
      daily: [
        { title: "Automate repetitive tasks", description: "Create custom prompts for common patterns" },
        { title: "Mentor others on AI usage", description: "Share your knowledge with teammates" },
        { title: "Explore AI APIs", description: "Build custom tools using AI APIs" }
      ],
      expert: [
        { title: "Build custom AI tools", description: "Create specialized tools for your team" },
        { title: "Contribute to AI tooling", description: "Help improve AI development tools" },
        { title: "Lead AI adoption initiatives", description: "Drive AI-native culture in your organization" }
      ]
    }

    return baseRecs[aiExp] || baseRecs.beginner
  }

  enableChat() {
    this.inputTarget.disabled = false
    this.sendButtonTarget.disabled = false
    this.inputTarget.placeholder = "Ask me anything about becoming AI-native..."
    this.inputTarget.focus()
  }

  async sendContextMessage() {
    const roleLabels = {
      frontend: "Frontend Developer",
      backend: "Backend Developer",
      fullstack: "Full Stack Developer",
      devops: "DevOps Engineer",
      data: "Data Engineer/Scientist",
      lead: "Tech Lead/Manager",
      other: "Developer"
    }

    const contextMessage = `I'm a ${roleLabels[this.userContext.role]} with ${this.userContext.experience} experience. My AI tool experience level is: ${this.userContext.ai_experience}. Please give me personalized advice on becoming more AI-native in my development work.`

    await this.sendMessageToAPI(contextMessage, true)
  }

  async sendMessage(event) {
    event.preventDefault()

    const content = this.inputTarget.value.trim()
    if (!content || !this.sessionToken) return

    this.inputTarget.value = ""
    await this.sendMessageToAPI(content)
  }

  async sendMessageToAPI(content, isSystemMessage = false) {
    // Add user message to UI (unless it's the initial context message)
    if (!isSystemMessage) {
      this.addMessage("user", content)
    }

    // Disable input while sending
    this.inputTarget.disabled = true
    this.sendButtonTarget.disabled = true

    // Add typing indicator
    const typingId = this.addTypingIndicator()

    try {
      const response = await fetch(`/embed/v1/sessions/${this.sessionToken}/messages`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Embed-Key": this.embedKeyValue
        },
        body: JSON.stringify({
          message: { content },
          stream: "false"
        })
      })

      // Remove typing indicator
      this.removeTypingIndicator(typingId)

      if (!response.ok) {
        throw new Error("Failed to send message")
      }

      const data = await response.json()
      this.addMessage("assistant", data.message.content)
      this.messageCount++

    } catch (error) {
      console.error("Message error:", error)
      this.removeTypingIndicator(typingId)
      this.addMessage("assistant", "Sorry, I encountered an error. Please try again.")
    } finally {
      this.inputTarget.disabled = false
      this.sendButtonTarget.disabled = false
      this.inputTarget.focus()
    }
  }

  addMessage(role, content) {
    const messagesContainer = this.messagesTarget

    const isUser = role === "user"
    const formattedContent = isUser ? this.escapeHtml(content) : this.renderMarkdown(content)

    // Check for score in AI response
    if (role === "assistant") {
      this.extractAndUpdateScore(content)
    }

    const messageHtml = `
      <div class="flex gap-3 ${isUser ? 'flex-row-reverse' : ''}">
        <div class="w-8 h-8 ${isUser ? 'bg-blue-500/20' : 'bg-emerald-500/20'} rounded-full flex items-center justify-center flex-shrink-0">
          ${isUser ? `
            <svg class="w-4 h-4 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          ` : `
            <svg class="w-4 h-4 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
          `}
        </div>
        <div class="${isUser ? 'bg-blue-600/30 rounded-tr-none' : 'bg-gray-700/50 rounded-tl-none'} rounded-xl px-4 py-3 max-w-[80%]">
          <div class="text-gray-200 prose prose-invert prose-sm max-w-none">${formattedContent}</div>
        </div>
      </div>
    `

    messagesContainer.insertAdjacentHTML("beforeend", messageHtml)
    messagesContainer.scrollTop = messagesContainer.scrollHeight
  }

  renderMarkdown(text) {
    // Escape HTML first
    let html = this.escapeHtml(text)

    // Headers (## Header)
    html = html.replace(/^## (.+)$/gm, '<h3 class="text-lg font-semibold text-emerald-400 mt-3 mb-2">$1</h3>')
    html = html.replace(/^### (.+)$/gm, '<h4 class="font-semibold text-white mt-2 mb-1">$1</h4>')

    // Bold (**text**)
    html = html.replace(/\*\*([^*]+)\*\*/g, '<strong class="font-semibold text-white">$1</strong>')

    // Bullet points
    html = html.replace(/^- (.+)$/gm, '<li class="ml-4 list-disc">$1</li>')
    // Wrap consecutive list items
    html = html.replace(/(<li[^>]*>.*<\/li>\n?)+/g, '<ul class="my-2 space-y-1">$&</ul>')

    // Numbered lists (1. item)
    html = html.replace(/^\d+\. (.+)$/gm, '<li class="ml-4 list-decimal">$1</li>')

    // Line breaks
    html = html.replace(/\n\n/g, '</p><p class="mt-2">')
    html = html.replace(/\n/g, '<br>')

    // Wrap in paragraph
    html = '<p>' + html + '</p>'

    // Clean up empty paragraphs
    html = html.replace(/<p><\/p>/g, '')
    html = html.replace(/<p>(<h[34])/g, '$1')
    html = html.replace(/(<\/h[34]>)<\/p>/g, '$1')
    html = html.replace(/<p>(<ul)/g, '$1')
    html = html.replace(/(<\/ul>)<\/p>/g, '$1')

    return html
  }

  extractAndUpdateScore(content) {
    // Look for score patterns like "Score: 65/100" or "65/100"
    const scoreMatch = content.match(/(\d{1,3})\/100/)
    if (scoreMatch) {
      const score = parseInt(scoreMatch[1])
      this.updateScoreDisplay(score)

      // Show NPS card after a delay when final score is given
      // Check if this looks like a final assessment (contains score breakdown keywords)
      const isFinalAssessment = content.toLowerCase().includes("tool awareness") ||
                                content.toLowerCase().includes("daily integration") ||
                                content.toLowerCase().includes("prompt skills") ||
                                content.toLowerCase().includes("next steps") ||
                                content.toLowerCase().includes("overall score")

      if (isFinalAssessment) {
        setTimeout(() => {
          this.showNpsCard()
        }, 2000)
      }
    }
  }

  updateScoreDisplay(score) {
    const scoreCard = document.getElementById("score-card")
    scoreCard.classList.remove("hidden")

    const scoreValue = document.getElementById("score-value")
    const scoreLabel = document.getElementById("score-label")
    const scoreBar = document.getElementById("score-bar")

    // Determine label based on score
    let label = "Just Starting"
    if (score >= 80) label = "AI Native"
    else if (score >= 65) label = "Proficient"
    else if (score >= 50) label = "Developing"
    else if (score >= 30) label = "Beginner"

    // Animate score counting
    let currentScore = parseInt(scoreValue.textContent) || 0
    const increment = score > currentScore ? 1 : -1
    const duration = 1000
    const steps = Math.abs(score - currentScore)
    const stepDuration = steps > 0 ? duration / steps : duration

    const counter = setInterval(() => {
      currentScore += increment
      scoreValue.textContent = currentScore

      if (currentScore === score) {
        clearInterval(counter)
        scoreLabel.textContent = label
      }
    }, stepDuration)

    // Update progress bar
    setTimeout(() => {
      scoreBar.style.width = `${score}%`
    }, 100)

    // Show recommendations card
    document.getElementById("recommendations-card").classList.remove("hidden")
  }

  addTypingIndicator() {
    const id = `typing-${Date.now()}`
    const html = `
      <div id="${id}" class="flex gap-3">
        <div class="w-8 h-8 bg-emerald-500/20 rounded-full flex items-center justify-center flex-shrink-0">
          <svg class="w-4 h-4 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
          </svg>
        </div>
        <div class="bg-gray-700/50 rounded-xl rounded-tl-none px-4 py-3">
          <div class="flex gap-1">
            <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0ms"></span>
            <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 150ms"></span>
            <span class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 300ms"></span>
          </div>
        </div>
      </div>
    `
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    return id
  }

  removeTypingIndicator(id) {
    const element = document.getElementById(id)
    if (element) element.remove()
  }

  insertPrompt(event) {
    const prompt = event.currentTarget.dataset.prompt
    if (this.inputTarget.disabled) {
      alert("Please complete the onboarding form first!")
      return
    }
    this.inputTarget.value = prompt
    this.inputTarget.focus()
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  // NPS Questionnaire methods
  selectNps(event) {
    const score = parseInt(event.currentTarget.dataset.score)
    this.selectedNpsScore = score

    // Update button styles
    const buttons = document.querySelectorAll("#nps-buttons button")
    buttons.forEach(btn => {
      const btnScore = parseInt(btn.dataset.score)
      btn.classList.remove("ring-2", "ring-emerald-400", "bg-emerald-500/30", "ring-red-400", "bg-red-500/30", "ring-yellow-400", "bg-yellow-500/30")

      if (btnScore === score) {
        // Color based on NPS category
        if (score <= 6) {
          btn.classList.add("ring-2", "ring-red-400", "bg-red-500/30")
        } else if (score <= 8) {
          btn.classList.add("ring-2", "ring-yellow-400", "bg-yellow-500/30")
        } else {
          btn.classList.add("ring-2", "ring-emerald-400", "bg-emerald-500/30")
        }
      }
    })

    // Show followup section and enable submit button
    document.getElementById("nps-followup").classList.remove("hidden")
    document.getElementById("nps-submit").disabled = false
  }

  submitNps(event) {
    event.preventDefault()

    if (this.selectedNpsScore === undefined) {
      return
    }

    const feedback = document.getElementById("nps-feedback").value.trim()

    // Log for demo purposes (in production, this would be sent to backend)
    console.log("NPS Submitted:", {
      score: this.selectedNpsScore,
      feedback: feedback,
      userContext: this.userContext
    })

    // Hide the form and show thank you message
    document.getElementById("nps-form").classList.add("hidden")
    document.getElementById("nps-thanks").classList.remove("hidden")

    // Add a message to the chat acknowledging the feedback
    setTimeout(() => {
      this.addMessage("assistant", "Thank you for your feedback! Your input helps us improve the AI-native assessment experience. Good luck on your journey to becoming more AI-native!")
    }, 500)
  }

  showNpsCard() {
    const npsCard = document.getElementById("nps-card")
    if (npsCard) {
      npsCard.classList.remove("hidden")
    }
  }
}
