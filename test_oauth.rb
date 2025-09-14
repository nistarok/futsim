#!/usr/bin/env ruby

require 'oauth2'

# Get the Google OAuth credentials from environment variables
client_id = ENV['GOOGLE_CLIENT_ID']
client_secret = ENV['GOOGLE_CLIENT_SECRET']

puts "Client ID: #{client_id}"
puts "Client Secret: #{client_secret ? '****' : 'NOT SET'}"

# Create an OAuth2 client
client = OAuth2::Client.new(
  client_id,
  client_secret,
  site: 'https://accounts.google.com',
  authorize_url: '/o/oauth2/auth',
  token_url: '/o/oauth2/token'
)

puts "OAuth2 client created successfully"

# Try to generate an authorization URL
begin
  auth_url = client.auth_code.authorize_url(
    redirect_uri: 'http://localhost:3000/auth/google_oauth2/callback',
    scope: 'email profile'
  )
  puts "Authorization URL generated successfully"
  puts "URL: #{auth_url}"
rescue => e
  puts "Error generating authorization URL: #{e.message}"
  puts e.backtrace
end