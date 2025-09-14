#!/usr/bin/env ruby

puts "Testing OAuth gem availability..."

begin
  require 'omniauth'
  puts "✅ omniauth gem is available"
rescue LoadError => e
  puts "❌ omniauth gem is NOT available: #{e.message}"
end

begin
  require 'omniauth-rails_csrf_protection'
  puts "✅ omniauth-rails_csrf_protection gem is available"
rescue LoadError => e
  puts "❌ omniauth-rails_csrf_protection gem is NOT available: #{e.message}"
end

begin
  require 'hashie'
  puts "✅ hashie gem is available"
rescue LoadError => e
  puts "❌ hashie gem is NOT available: #{e.message}"
end

begin
  require 'rack/protection'
  puts "✅ rack-protection gem is available"
rescue LoadError => e
  puts "❌ rack-protection gem is NOT available: #{e.message}"
end