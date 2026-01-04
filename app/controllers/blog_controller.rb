# frozen_string_literal: true

class BlogController < ApplicationController
  ARTICLES = [
    {
      slug: "5-ai-skills-teams-need-2026",
      title: "5 AI Skills Teams Need to Stay Competitive (2026)",
      excerpt: "Discover the essential AI competencies your engineering team needs to thrive in 2026. From prompt engineering to AI-assisted architecture decisions, learn what separates high-performing teams from the rest.",
      published_at: Date.new(2026, 1, 1),
      reading_time: 8,
      category: "Team Skills"
    },
    {
      slug: "software-ai-skills-every-employee-needs-2026",
      title: "Software AI Skills Every Employee Needs In 2026",
      excerpt: "From prompt engineering to AI-assisted debugging, these are the fundamental AI skills every software professional needs to master in 2026 to remain effective and valuable.",
      published_at: Date.new(2026, 1, 1),
      reading_time: 10,
      category: "Individual Skills"
    },
    {
      slug: "hiring-gen-ai-business-success",
      title: "Guide to Hiring people knowing Gen AI for Business Success",
      excerpt: "How to identify and recruit AI-savvy talent that will drive your organization's AI transformation. Practical interview questions, skill assessments, and red flags to watch for.",
      published_at: Date.new(2026, 1, 1),
      reading_time: 7,
      category: "Hiring"
    },
    {
      slug: "ai-workplace-report-2026",
      title: "AI in the workplace: A report for 2026",
      excerpt: "An in-depth analysis of AI adoption trends, challenges, and opportunities across software development teams. Data-driven insights on what's working and what's not.",
      published_at: Date.new(2026, 1, 1),
      reading_time: 12,
      category: "Research"
    },
    {
      slug: "10-steps-ai-value-software-development",
      title: "10 steps to make AI bring actual value in software development",
      excerpt: "Practical strategies for moving beyond AI hype to real productivity gains. A step-by-step guide to implementing AI tools that actually improve your team's output.",
      published_at: Date.new(2026, 1, 1),
      reading_time: 9,
      category: "Implementation"
    }
  ].freeze

  AUTHOR = {
    name: "Risto Holappa",
    role: "CTO and founder",
    email: "risto@viher.it",
    linkedin: "https://www.linkedin.com/in/rholappa/"
  }.freeze

  def index
    @articles = ARTICLES
    @author = AUTHOR
  end

  def show
    @article = ARTICLES.find { |a| a[:slug] == params[:slug] }
    return redirect_to blog_path, alert: "Article not found" unless @article

    @author = AUTHOR
  end
end
