# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do NOT** open a public GitHub issue
2. Email security concerns to **security@devometric.com**
3. Include detailed steps to reproduce
4. Allow time for us to address the issue before public disclosure

## Security Best Practices

### Self-Hosted Deployments

1. **Use HTTPS** - Always run behind a TLS-terminating reverse proxy
2. **Secure secrets** - Never commit `.env` files or API keys
3. **Update regularly** - Keep Docker images and dependencies updated
4. **Network isolation** - Run Ollama on internal network only
5. **Firewall** - Only expose necessary ports

### API Keys

- Anthropic/OpenAI API keys are encrypted at rest (AES-256-GCM)
- Use BYOK feature for company-specific keys
- Rotate keys periodically

### Data Protection

- Chat sessions are stored in PostgreSQL
- Consider encryption at rest for the database
- Implement regular backups
- Review data retention policies

## Known Security Considerations

### Prompt Injection

The application includes basic prompt injection filtering. However, no filter is perfect. Consider:

- Reviewing AI responses before acting on them
- Training users on AI safety
- Monitoring for unusual activity

### Airgapped Deployments

For maximum security, deploy with Ollama in a completely airgapped environment. This ensures:

- No data leaves your network
- No external API calls
- Full control over the AI model
