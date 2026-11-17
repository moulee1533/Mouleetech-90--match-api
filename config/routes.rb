Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  mount ActionCable.server => "/cable"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      get  "auth/me", to: "auth#me"

      get "digilocker/authorize", to: "digilocker#authorize"
      get "digilocker/callback", to: "digilocker#callback"
      get "digilocker/status", to: "digilocker#status"
      post "digilocker/mock_verify", to: "digilocker#mock_verify"

      get "dashboard", to: "dashboard#show"
      get "matches", to: "matches#index"

      post "interests", to: "interests#create"
      get "interests/received", to: "interests#received"
      get "interests/sent", to: "interests#sent"
      patch "interests/:id", to: "interests#update"
      put "interests/:id", to: "interests#update"
      post "interests/:id/accept", to: "interests#accept"
      post "interests/:id/decline", to: "interests#decline"

      post "reports", to: "reports#create"

      get "shortlists", to: "shortlists#index"
      post "shortlists", to: "shortlists#create"
      delete "shortlists/:target_user_id", to: "shortlists#destroy"

      post "passes", to: "profile_passes#create"
      delete "passes/:passed_user_id", to: "profile_passes#destroy"

      get "presence/:user_id", to: "presence#show"
      post "presence/heartbeat", to: "presence#heartbeat"

      get "conversations", to: "conversations#index"
      get "conversations/:id/messages", to: "conversations#messages"
      post "conversations/:id/messages", to: "conversations#create_message"
      post "conversations/:id/delivered", to: "conversations#delivered"
      post "conversations/:id/read", to: "conversations#read"

      post "device_tokens", to: "device_tokens#create"
      delete "device_tokens", to: "device_tokens#destroy"

      get "profiles/search", to: "profiles#search"
      get "profiles/:id", to: "profiles#public_show"

      get "profile", to: "profiles#show"
      put "profile/update", to: "profiles#update_profile"
      put "profile/basic", to: "profiles#basic"
      put "profile/family", to: "profiles#family"
      put "profile/career", to: "profiles#career"
      put "profile/location", to: "profiles#location"
      put "profile/partner", to: "profiles#partner"

      post "profile/avatar", to: "profile_photos#create_avatar"
      post "profile/photos", to: "profile_photos#create"
      delete "profile/photos/:id", to: "profile_photos#destroy"
      put "profile/avatar/from_photo/:id", to: "profile_photos#promote"

      namespace :admin do
        post "auth/login", to: "auth#login"
        post "auth/logout", to: "auth#logout"
        get  "auth/me", to: "auth#me"

        get "dashboard", to: "dashboard#show"
        resources :users, only: %i[index show]
        resources :digilocker_sessions, only: %i[index]
      end
    end
  end
end
