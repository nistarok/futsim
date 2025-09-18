Rails.application.routes.draw do
  resources :rooms do
    member do
      patch :choose_random_club
    end
    resources :clubs, only: [:new, :create]
  end
  resources :clubs do
    member do
      get :squad
      get :lineup
      get :rounds
      post :create_lineup
      patch :update_lineup
      patch :update, as: :claim
    end
    resources :lineups
  end
  get "profile", to: "profiles#show"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # OAuth routes
  post '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  delete '/sign_out', to: 'sessions#destroy', as: 'sign_out'

  # Invitation routes
  resources :invitations, only: [:index, :create, :destroy]

  # Development only: direct login routes
  if Rails.env.development?
    get '/dev/login_admin', to: 'sessions#dev_login_admin'
    get '/dev/login_player', to: 'sessions#dev_login_player'
    get '/dev/logout', to: 'sessions#dev_logout'
  end

  # Defines the root path route ("/")
  root "pages#home"
end

