# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  # Configure Google OAuth2
  # For development, you can use environment variables
  # In production, use Rails.application.credentials
  if Rails.env.development?
    provider :google_oauth2, 
             ENV['GOOGLE_CLIENT_ID'], 
             ENV['GOOGLE_CLIENT_SECRET'], 
             {
               scope: 'email,profile',
               image_aspect_ratio: 'square',
               image_size: 50,
               callback_path: '/auth/google_oauth2/callback',
               redirect_uri: 'http://localhost:3000/auth/google_oauth2/callback'
             }
  else
    # For production, you would use credentials:
    # provider :google_oauth2, Rails.application.credentials.google[:client_id], Rails.application.credentials.google[:client_secret], {
    #   scope: 'email,profile',
    #   image_aspect_ratio: 'square',
    #   image_size: 50,
    #   callback_path: '/auth/google_oauth2/callback',
    #   redirect_uri: 'https://your-production-domain.com/auth/google_oauth2/callback'
    # }
  end
end

# Configure OmniAuth to use POST requests
OmniAuth.config.allowed_request_methods = [:post]

# Configure OmniAuth to skip CSRF protection (not recommended for production)
OmniAuth.config.request_validation_phase = lambda do |env|
  # Skip validation for development
end