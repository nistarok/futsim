ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "capybara/rails"
require "capybara/minitest"

# Load test helpers
require_relative "support/lineup_test_helper"

# Configurações específicas para testes do sistema de escalação
class ActiveSupport::TestCase
  # Executar testes em transações paralelas
  parallelize(workers: :number_of_processors)

  # Setup das fixtures
  fixtures :all

  # Include helper para todos os testes
  include LineupTestHelper

  # Configurações para Capybara
  Capybara.register_driver :headless_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--remote-debugging-port=9222')
    options.add_argument('--disable-extensions')
    options.add_argument('--window-size=1400,1400')

    Selenium::WebDriver.logger.level = :error if defined?(Selenium::WebDriver)

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.javascript_driver = :headless_chrome
  Capybara.default_max_wait_time = 5
  Capybara.server_port = 3001 # Porta diferente para evitar conflitos

  # Configurações de timeout
  Capybara.default_normalize_ws = true
  Capybara.ignore_hidden_elements = true

  # Helper para setup de teste
  def setup_test_environment
    # Limpar cache entre testes
    Rails.cache.clear if Rails.cache.respond_to?(:clear)

    # Resetar estado do Stimulus se necessário
    # Configurações específicas podem ir aqui
  end

  # Helper para teardown
  def cleanup_test_environment
    # Limpeza específica após cada teste
  end
end

# Configurações para testes de integração
class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def setup
    super
    setup_test_environment
  end

  def teardown
    cleanup_test_environment
    super
  end
end

# Configurações para testes de sistema
class ActionDispatch::SystemTestCase
  def setup
    super
    setup_test_environment
  end

  def teardown
    cleanup_test_environment
    super
  end
end

# Configurações de logging para testes
Rails.logger.level = Logger::WARN

# Desabilitar logs verbose do Selenium
Selenium::WebDriver.logger.level = :error if defined?(Selenium::WebDriver)

# Configurações de performance para testes
if defined?(Bullet)
  Bullet.enable = false # Desabilitar Bullet em testes
end

# Helper global para debugging
def debug_test_state
  puts "\n=== DEBUG TEST STATE ==="
  puts "Current test: #{self.class.name}##{method_name}"
  puts "Database: #{ActiveRecord::Base.connection.current_database}"
  puts "Players count: #{Player.count}"
  puts "Clubs count: #{Club.count}"
  puts "========================\n"
end