Rails.application.routes.draw do
  resources :rooms
  resources :clubs do
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

  # Defines the root path route ("/")
  root "pages#home"
end

