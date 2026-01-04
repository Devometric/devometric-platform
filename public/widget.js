(function() {
  'use strict';

  const WIDGET_VERSION = '1.0.0';

  // Auto-detect API URL based on where the script is loaded from
  function getDefaultApiUrl() {
    if (window.RTN_API_URL) return window.RTN_API_URL;

    // Try to get the URL from the script src
    const scripts = document.getElementsByTagName('script');
    for (let i = 0; i < scripts.length; i++) {
      const src = scripts[i].src;
      if (src && src.includes('widget.js')) {
        const url = new URL(src);
        return url.origin;
      }
    }

    // Fallback for localhost development
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
      return 'http://localhost:3000';
    }

    return 'https://api.devometric.com';
  }

  const DEFAULT_API_URL = getDefaultApiUrl();

  class DevometricWidget {
    constructor(config) {
      this.config = {
        embedKey: config.embedKey || config.key,
        position: config.position || 'bottom-right',
        apiUrl: config.apiUrl || DEFAULT_API_URL,
        externalUserId: config.externalUserId || null,
        userContext: config.userContext || {},
        locale: config.locale || 'en',
        primaryColor: config.primaryColor || '#4F46E5',
        onReady: config.onReady || function() {},
        onMessage: config.onMessage || function() {},
        onError: config.onError || function() {}
      };

      this.sessionToken = null;
      this.isOpen = false;
      this.isLoading = false;
      this.messages = [];

      this.init();
    }

    async init() {
      try {
        console.log('[Devometric] Initializing widget with API URL:', this.config.apiUrl);
        this.injectStyles();
        this.createWidget();
        await this.initSession();
        this.config.onReady(this);
      } catch (error) {
        console.error('[Devometric] Initialization failed:', error);
        this.config.onError(error);
        // Show error in widget if it exists
        if (this.messagesContainer) {
          this.addMessage('assistant', 'Failed to initialize: ' + error.message);
        }
      }
    }

    injectStyles() {
      if (document.getElementById('rtn-widget-styles')) return;

      const styles = document.createElement('style');
      styles.id = 'rtn-widget-styles';
      styles.textContent = `
        .rtn-widget-container {
          position: fixed;
          z-index: 999999;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
        }
        .rtn-widget-container.bottom-right {
          bottom: 20px;
          right: 20px;
        }
        .rtn-widget-container.bottom-left {
          bottom: 20px;
          left: 20px;
        }
        .rtn-widget-button {
          width: 60px;
          height: 60px;
          border-radius: 50%;
          border: none;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 4px 12px rgba(0,0,0,0.15);
          transition: transform 0.2s, box-shadow 0.2s;
        }
        .rtn-widget-button:hover {
          transform: scale(1.05);
          box-shadow: 0 6px 16px rgba(0,0,0,0.2);
        }
        .rtn-widget-button svg {
          width: 28px;
          height: 28px;
          fill: white;
        }
        .rtn-chat-window {
          position: absolute;
          bottom: 80px;
          width: 380px;
          height: 550px;
          background: white;
          border-radius: 16px;
          box-shadow: 0 8px 32px rgba(0,0,0,0.15);
          display: none;
          flex-direction: column;
          overflow: hidden;
        }
        .rtn-widget-container.bottom-right .rtn-chat-window {
          right: 0;
        }
        .rtn-widget-container.bottom-left .rtn-chat-window {
          left: 0;
        }
        .rtn-chat-window.open {
          display: flex;
        }
        .rtn-chat-header {
          padding: 16px 20px;
          color: white;
          display: flex;
          align-items: center;
          justify-content: space-between;
        }
        .rtn-chat-header h3 {
          margin: 0;
          font-size: 16px;
          font-weight: 600;
        }
        .rtn-close-button {
          background: none;
          border: none;
          color: white;
          cursor: pointer;
          padding: 4px;
          opacity: 0.8;
        }
        .rtn-close-button:hover {
          opacity: 1;
        }
        .rtn-chat-messages {
          flex: 1;
          overflow-y: auto;
          padding: 16px;
          display: flex;
          flex-direction: column;
          gap: 12px;
        }
        .rtn-message {
          max-width: 85%;
          padding: 12px 16px;
          border-radius: 12px;
          line-height: 1.5;
          font-size: 14px;
        }
        .rtn-message.user {
          align-self: flex-end;
          color: white;
        }
        .rtn-message.assistant {
          align-self: flex-start;
          background: #f3f4f6;
          color: #1f2937;
        }
        .rtn-message.assistant pre {
          background: #1f2937;
          color: #e5e7eb;
          padding: 12px;
          border-radius: 8px;
          overflow-x: auto;
          font-size: 13px;
        }
        .rtn-message.assistant code {
          background: #e5e7eb;
          padding: 2px 6px;
          border-radius: 4px;
          font-size: 13px;
        }
        .rtn-message.assistant pre code {
          background: none;
          padding: 0;
        }
        .rtn-typing-indicator {
          display: flex;
          gap: 4px;
          padding: 12px 16px;
          background: #f3f4f6;
          border-radius: 12px;
          align-self: flex-start;
        }
        .rtn-typing-indicator span {
          width: 8px;
          height: 8px;
          background: #9ca3af;
          border-radius: 50%;
          animation: rtn-typing 1s infinite;
        }
        .rtn-typing-indicator span:nth-child(2) {
          animation-delay: 0.2s;
        }
        .rtn-typing-indicator span:nth-child(3) {
          animation-delay: 0.4s;
        }
        @keyframes rtn-typing {
          0%, 100% { opacity: 0.4; }
          50% { opacity: 1; }
        }
        .rtn-chat-input {
          padding: 16px;
          border-top: 1px solid #e5e7eb;
          display: flex;
          gap: 8px;
        }
        .rtn-chat-input input {
          flex: 1;
          padding: 12px 16px;
          border: 1px solid #e5e7eb;
          border-radius: 24px;
          font-size: 14px;
          outline: none;
        }
        .rtn-chat-input input:focus {
          border-color: var(--rtn-primary-color);
        }
        .rtn-send-button {
          width: 44px;
          height: 44px;
          border-radius: 50%;
          border: none;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .rtn-send-button:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
        .rtn-send-button svg {
          width: 20px;
          height: 20px;
          fill: white;
        }
      `;
      document.head.appendChild(styles);
    }

    createWidget() {
      const container = document.createElement('div');
      container.className = `rtn-widget-container ${this.config.position}`;
      container.style.setProperty('--rtn-primary-color', this.config.primaryColor);

      container.innerHTML = `
        <div class="rtn-chat-window">
          <div class="rtn-chat-header" style="background: ${this.config.primaryColor}">
            <h3>AI Assistant</h3>
            <button class="rtn-close-button" aria-label="Close">
              <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
                <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
              </svg>
            </button>
          </div>
          <div class="rtn-chat-messages"></div>
          <div class="rtn-chat-input">
            <input type="text" placeholder="Ask me anything..." />
            <button class="rtn-send-button" style="background: ${this.config.primaryColor}">
              <svg viewBox="0 0 24 24" fill="currentColor">
                <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/>
              </svg>
            </button>
          </div>
        </div>
        <button class="rtn-widget-button" style="background: ${this.config.primaryColor}" aria-label="Open chat">
          <svg viewBox="0 0 24 24">
            <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H6l-2 2V4h16v12z"/>
          </svg>
        </button>
      `;

      document.body.appendChild(container);
      this.container = container;
      this.chatWindow = container.querySelector('.rtn-chat-window');
      this.messagesContainer = container.querySelector('.rtn-chat-messages');
      this.input = container.querySelector('.rtn-chat-input input');
      this.sendButton = container.querySelector('.rtn-send-button');

      this.bindEvents();
    }

    bindEvents() {
      const toggleButton = this.container.querySelector('.rtn-widget-button');
      const closeButton = this.container.querySelector('.rtn-close-button');

      toggleButton.addEventListener('click', () => this.toggle());
      closeButton.addEventListener('click', () => this.close());

      this.input.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          this.sendMessage();
        }
      });

      this.sendButton.addEventListener('click', () => this.sendMessage());
    }

    async initSession() {
      const response = await this.apiCall('POST', '/embed/v1/init', {
        external_user_id: this.config.externalUserId,
        user_context: this.config.userContext,
        locale: this.config.locale
      });

      this.sessionToken = response.session_token;

      if (response.welcome_message) {
        this.addMessage('assistant', response.welcome_message);
      }
    }

    toggle() {
      this.isOpen ? this.close() : this.open();
    }

    open() {
      this.isOpen = true;
      this.chatWindow.classList.add('open');
      this.input.focus();
    }

    close() {
      this.isOpen = false;
      this.chatWindow.classList.remove('open');
    }

    async sendMessage() {
      const content = this.input.value.trim();
      if (!content || this.isLoading) return;

      this.input.value = '';
      this.addMessage('user', content);
      this.showTypingIndicator();
      this.isLoading = true;
      this.sendButton.disabled = true;

      try {
        const response = await this.apiCall('POST', `/embed/v1/sessions/${this.sessionToken}/messages`, {
          message: { content }
        });

        this.hideTypingIndicator();
        this.addMessage('assistant', response.message.content);
        this.config.onMessage(response.message);
      } catch (error) {
        this.hideTypingIndicator();
        console.error('[Devometric] Message error:', error);
        this.addMessage('assistant', 'Sorry, I encountered an error: ' + error.message);
        this.config.onError(error);
      } finally {
        this.isLoading = false;
        this.sendButton.disabled = false;
      }
    }

    addMessage(role, content) {
      const message = { role, content, timestamp: new Date() };
      this.messages.push(message);

      const messageEl = document.createElement('div');
      messageEl.className = `rtn-message ${role}`;
      messageEl.style.background = role === 'user' ? this.config.primaryColor : '';
      messageEl.innerHTML = this.formatContent(content);

      this.messagesContainer.appendChild(messageEl);
      this.scrollToBottom();
    }

    formatContent(content) {
      // Simple markdown-like formatting
      return content
        .replace(/```(\w*)\n([\s\S]*?)```/g, '<pre><code>$2</code></pre>')
        .replace(/`([^`]+)`/g, '<code>$1</code>')
        .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
        .replace(/\n/g, '<br>');
    }

    showTypingIndicator() {
      const indicator = document.createElement('div');
      indicator.className = 'rtn-typing-indicator';
      indicator.innerHTML = '<span></span><span></span><span></span>';
      this.messagesContainer.appendChild(indicator);
      this.scrollToBottom();
    }

    hideTypingIndicator() {
      const indicator = this.messagesContainer.querySelector('.rtn-typing-indicator');
      if (indicator) indicator.remove();
    }

    scrollToBottom() {
      this.messagesContainer.scrollTop = this.messagesContainer.scrollHeight;
    }

    async apiCall(method, path, body = null) {
      const url = `${this.config.apiUrl}${path}`;
      const options = {
        method,
        headers: {
          'Content-Type': 'application/json',
          'X-Embed-Key': this.config.embedKey
        }
      };

      if (body) {
        options.body = JSON.stringify(body);
      }

      const response = await fetch(url, options);

      if (!response.ok) {
        const error = await response.json().catch(() => ({ error: 'Unknown error' }));
        throw new Error(error.error || 'API request failed');
      }

      return response.json();
    }

    // Public API
    setUserContext(context) {
      this.config.userContext = { ...this.config.userContext, ...context };
      if (this.sessionToken) {
        this.apiCall('PATCH', `/embed/v1/sessions/${this.sessionToken}/context`, {
          context: this.config.userContext
        }).catch(console.error);
      }
    }

    clearHistory() {
      this.messages = [];
      this.messagesContainer.innerHTML = '';
      this.initSession();
    }
  }

  // Auto-initialize from script tag
  function autoInit() {
    const script = document.currentScript || document.querySelector('script[data-key]');
    if (!script) return;

    const embedKey = script.getAttribute('data-key');
    if (!embedKey) return;

    const config = {
      embedKey,
      position: script.getAttribute('data-position') || 'bottom-right',
      apiUrl: script.getAttribute('data-api-url'),
      externalUserId: script.getAttribute('data-user-id'),
      primaryColor: script.getAttribute('data-color'),
      locale: script.getAttribute('data-locale')
    };

    window.Devometric = new DevometricWidget(config);
  }

  // Export for manual initialization
  window.DevometricWidget = DevometricWidget;

  // Auto-init on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', autoInit);
  } else {
    autoInit();
  }
})();
