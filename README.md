# Devometric

> Feature-rich, self-hostable AI adoption coach that helps software engineers become AI-native developers.

**Devometric** is an open-source platform that companies can deploy to help their engineering teams embrace AI-powered development. Configure it with your company's policies, coding standards, and work culture to provide contextual AI assistance.

## Editions

### Devometric Community Edition (CE)

Available freely under the [MIT license](LICENSE). Includes all core features for teams of any size.

### Devometric Enterprise Edition (EE)

Includes extra features that are primarily useful for larger organizations. For feature details, check out [devometric.com](https://devometric.com).

## Features

- **Configurable LLM** - Works with Ollama (local), OpenAI, or Anthropic
- **Airgapped Deployment** - Run completely offline with Ollama and local models
- **Company Configuration** - Custom AI instructions, policies, coding standards, work culture
- **Embeddable Widget** - Secure JavaScript widget for internal portals
- **Domain Whitelisting** - Control where the chatbot can be embedded
- **Usage Analytics** - Track messages, sessions, and user engagement
- **SSO Integration** - Identify users via external IDs for personalized responses
- **Multi-language** - Supports English, Finnish, Spanish, German, Swedish
- **BYOK (Bring Your Own Key)** - Companies can use their own API keys
- **Streaming Responses** - Real-time AI responses with Server-Sent Events

## Quick Start (Self-Hosted)

### Prerequisites
- Docker and Docker Compose
- 8GB+ RAM (for running local LLM)

### 1. Clone and Configure

```bash
git clone git@github.com:Devometric/devometric-platform.git
cd devometric-platform

# Configure environment
cp .env.example .env
# Edit .env - defaults work for local deployment!
```

### 2. Start Services

```bash
# Start all services (includes Ollama for local AI)
docker compose -f docker-compose.self-hosted.yml up -d

# Wait for services to be healthy
docker compose -f docker-compose.self-hosted.yml ps

# Setup database
docker compose -f docker-compose.self-hosted.yml exec app rails db:setup
```

### 3. Pull an AI Model

```bash
# Pull Llama 3.2 (default, 3B parameters, ~2GB)
docker compose -f docker-compose.self-hosted.yml exec ollama ollama pull llama3.2

# Or pull a larger model for better quality
docker compose -f docker-compose.self-hosted.yml exec ollama ollama pull llama3.1:8b
```

### 4. Access the Dashboard

Open http://localhost:3000 and create your first company account.

## LLM Providers

Devometric supports multiple LLM providers. Configure via environment variables:

### Ollama (Recommended for Self-Hosted)

Runs completely locally - no API keys, no internet required. Perfect for airgapped environments.

```bash
LLM_PROVIDER=ollama
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=llama3.2
```

**Available models:**
- `llama3.2` - 3B parameters, fast and efficient (default)
- `llama3.1:8b` - 8B parameters, better quality
- `llama3.1:70b` - 70B parameters, highest quality (requires 48GB+ RAM)
- `codellama` - Optimized for code
- `mistral` - Fast and capable

### OpenAI

```bash
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o
```

### Anthropic

```bash
LLM_PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-sonnet-4-20250514
```

## Airgapped Deployment

For completely offline deployments:

1. Pre-pull Docker images on a connected machine:
```bash
docker pull postgres:16-alpine
docker pull redis:7-alpine
docker pull ollama/ollama:latest
docker save postgres:16-alpine redis:7-alpine ollama/ollama:latest > images.tar
```

2. Pre-pull Ollama model:
```bash
docker run -v ollama_data:/root/.ollama ollama/ollama pull llama3.2
docker run -v ollama_data:/root/.ollama ollama/ollama list  # Verify
```

3. Transfer images and model data to airgapped environment

4. Load and run:
```bash
docker load < images.tar
docker compose -f docker-compose.self-hosted.yml up -d
```

## Embedding the Widget

Add this script to your internal portal:

```html
<script
  src="https://your-deployment.com/widget.js"
  data-key="YOUR_EMBED_KEY"
  data-position="bottom-right"
></script>
```

## Tech Stack

- **Rails 8** - API and admin dashboard
- **PostgreSQL 16** - Database
- **Redis 7** - Caching and job queues
- **Ollama** - Local LLM runtime
- **Hotwire** - Real-time streaming
- **TailwindCSS** - Styling

## Development

```bash
# Start dependencies
docker compose up -d

# Pull Ollama model
docker compose exec ollama ollama pull llama3.2

# Install Ruby dependencies
bundle install

# Setup database
rails db:setup

# Start dev server
bin/dev
```

### Running Tests

```bash
bundle exec rspec
```

### Linting

```bash
bundle exec rubocop
```

## API Documentation

See [docs/API_SPECIFICATION.md](docs/API_SPECIFICATION.md) for the complete API reference.

### Key Endpoints

**Admin API** (`/admin/v1`)
- `POST /auth/register` - Create admin account
- `GET /configuration` - Get AI configuration
- `PATCH /configuration` - Update AI settings
- `GET /dashboard` - Usage statistics

**Embed API** (`/embed/v1`)
- `POST /init` - Initialize chat session
- `POST /sessions/:token/messages` - Send message (supports streaming)

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LLM_PROVIDER` | `ollama` | LLM provider: `ollama`, `openai`, `anthropic` |
| `OLLAMA_HOST` | `http://localhost:11434` | Ollama server URL |
| `OLLAMA_MODEL` | `llama3.2` | Ollama model name |
| `OPENAI_API_KEY` | - | OpenAI API key |
| `OPENAI_MODEL` | `gpt-4o` | OpenAI model |
| `ANTHROPIC_API_KEY` | - | Anthropic API key |
| `ANTHROPIC_MODEL` | `claude-sonnet-4-20250514` | Anthropic model |
| `POSTGRES_PASSWORD` | `password` | PostgreSQL password |
| `SECRET_KEY_BASE` | - | Rails secret key |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Internal Portal                      │
│                    ┌─────────────────┐                       │
│                    │  Embed Widget   │                       │
│                    └────────┬────────┘                       │
└─────────────────────────────┼───────────────────────────────┘
                              │ HTTPS
┌─────────────────────────────▼───────────────────────────────┐
│                        Devometric                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Rails   │  │PostgreSQL│  │  Redis   │  │  Ollama  │    │
│  │   App    │◄─┤    DB    │  │  Cache   │  │   LLM    │    │
│  └────┬─────┘  └──────────┘  └──────────┘  └────▲─────┘    │
│       │                                          │          │
│       └──────────────────────────────────────────┘          │
│                    Local LLM Inference                       │
└─────────────────────────────────────────────────────────────┘
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Devometric Community Edition is available under the [MIT License](LICENSE).

## Support

- **Issues**: [GitHub Issues](https://github.com/Devometric/devometric-platform/issues)
- **Website**: [devometric.com](https://devometric.com)
