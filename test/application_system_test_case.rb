require "test_helper"
require "capybara/rails"
require "capybara/minitest"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |driver_options|
    driver_options.add_argument('--no-sandbox')
    driver_options.add_argument('--disable-dev-shm-usage')
    driver_options.add_argument('--disable-gpu')
    driver_options.add_argument('--remote-debugging-port=9222')
    driver_options.add_argument('--disable-extensions')
    driver_options.add_argument('--disable-web-security')
    driver_options.add_argument('--allow-running-insecure-content')
  end

  include Capybara::Screenshot::MiniTestPlugin
  include LineupTestHelper

  # Setup para todos os testes de sistema
  def setup
    super
    Capybara.default_max_wait_time = 5
    Capybara.enable_aria_label = true
  end

  def teardown
    super
    Capybara.reset_sessions!
  end

  private

  # Helper para login nos testes de sistema
  def login_as(user)
    # Por enquanto, vamos assumir que o usuário já está autenticado
    # via fixtures ou setup do teste
    # TODO: Implementar lógica de login específica quando sistema de auth estiver definido
    visit root_path rescue nil
  end

  # Helper para aguardar JavaScript
  def wait_for_javascript
    sleep 0.1 while page.evaluate_script('typeof jQuery !== "undefined" && jQuery.active > 0')
  end

  # Helper para aguardar Stimulus
  def wait_for_stimulus
    assert_selector '[data-controller]', wait: 5
  end

  # Helper para debug de testes
  def debug_page_state
    puts "Current URL: #{current_url}"
    puts "Page title: #{page.title}"
    puts "Page has content: #{page.has_content?('anything')}"
    puts "Selected elements: #{all('.selected').count}"
  end

  # Helper para aceitar alerts de forma segura
  def safe_accept_alert
    begin
      accept_alert
    rescue Selenium::WebDriver::Error::NoSuchAlertError
      # Continuar se não houver alert
    end
  end

  # Helper para verificar responsividade
  def test_responsive_breakpoints
    breakpoints = [
      [375, 667],   # Mobile portrait
      [768, 1024],  # Tablet portrait
      [1024, 768],  # Tablet landscape
      [1920, 1080]  # Desktop
    ]

    breakpoints.each do |width, height|
      page.driver.browser.manage.window.resize_to(width, height)
      yield width, height if block_given?
    end
  end
end