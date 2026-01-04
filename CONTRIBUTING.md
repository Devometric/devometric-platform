# Contributing to Devometric

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and constructive in all interactions. We welcome contributors of all experience levels.

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Use the bug report template
3. Include steps to reproduce, expected vs actual behavior
4. Include environment details (OS, Docker version, LLM provider)

### Suggesting Features

1. Check existing issues and discussions
2. Use the feature request template
3. Explain the use case and expected behavior

### Submitting Code

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Run tests: `bundle exec rspec`
5. Run linter: `bundle exec rubocop`
6. Commit with a clear message
7. Push and create a Pull Request

## Development Setup

### Prerequisites

- Ruby 3.3+
- Docker and Docker Compose
- PostgreSQL 16 (via Docker)
- Redis 7 (via Docker)

### Local Setup

```bash
# Clone your fork
git clone git@github.com:Devometric/devometric-platform.git
cd devometric-platform

# Start dependencies
docker compose up -d

# Install gems
bundle install

# Setup database
rails db:setup

# Pull Ollama model (for AI features)
docker compose exec ollama ollama pull llama3.2

# Start dev server
bin/dev
```

### Running Tests

```bash
bundle exec rspec
```

### Code Style

We use RuboCop for Ruby code style. Run before committing:

```bash
bundle exec rubocop
bundle exec rubocop -a  # Auto-fix
```

## Pull Request Guidelines

- Keep PRs focused on a single change
- Update tests for new features
- Update documentation if needed
- Ensure CI passes
- Request review from maintainers

## Project Structure

```
app/
├── controllers/     # API endpoints
├── models/          # ActiveRecord models
├── services/        # Business logic
│   └── ai/          # LLM provider clients
├── jobs/            # Background jobs
└── channels/        # WebSocket channels

config/              # Rails configuration
db/                  # Database migrations
docs/                # Documentation
```

## LLM Provider Development

When adding a new LLM provider:

1. Create a new client in `app/services/ai/`
2. Extend `AI::BaseClient`
3. Implement `chat`, `available?`, `provider_name`
4. Register in `AI::LLMProvider`
5. Add environment variables to `.env.example`
6. Update documentation

## Questions?

- Open a GitHub Issue for questions
- Check existing issues and PRs
- Read the documentation in `/docs`

Thank you for contributing!
