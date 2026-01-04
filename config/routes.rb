Rails.application.routes.draw do
  # Admin API (JSON endpoints for dashboard frontend)
  namespace :admin do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      post "auth/register", to: "auth#register"
      delete "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"

      resource :configuration, only: [:show, :update] do
        post :test
      end

      resources :embed_domains, only: [:index, :create, :update, :destroy]

      resource :dashboard, only: [:show], controller: "dashboard" do
        get :usage
      end

      resources :chat_sessions, only: [:index, :show]

      resource :subscription, only: [:show] do
        post :checkout
        post :portal
      end

      resource :api_key, only: [:show, :update, :destroy] do
        post :test
      end

      resource :security, only: [:show, :update] do
        post :export
        delete :data, action: :destroy_data
      end
    end
  end

  # Embed API for the chat widget
  namespace :embed do
    namespace :v1 do
      post :init, to: "widget#init"
      get :config, to: "widget#show_config"

      post "sessions/resume", to: "sessions#resume"
      get "sessions/:session_token/history", to: "sessions#history"
      patch "sessions/:session_token/context", to: "sessions#update_context"

      post "sessions/:session_token/messages", to: "messages#create"
    end
  end

  # Webhooks
  namespace :webhooks do
    post "stripe", to: "stripe#create"
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Demo page for testing the widget
  get "demo", to: "home#demo"

  # Root - welcome page for Community Edition
  root "home#welcome"
end
