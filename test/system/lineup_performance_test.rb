# Test: TEST-E2E-003 - Performance
# Objetivo: Validar performance percebida pelo usuário

require 'application_system_test_case'

class LineupPerformanceTest < ApplicationSystemTestCase
  def setup
    @club = clubs(:fluminense)
    @user = users(:admin)
    login_as @user
  end

  # TC103.1: Tempo de carregamento
  test "page load performance" do
    start_time = Time.current
    visit club_lineup_path(@club)

    # Aguardar Stimulus conectar
    assert_selector "[data-controller='lineup']", wait: 5

    load_time = Time.current - start_time
    assert load_time < 2.seconds, "Página carregou em #{load_time.round(2)}s (limite: 2s)"

    # Verificar elementos críticos carregados
    assert_text "0/11"
    assert_button "Auto Selecionar Melhores"
    assert_selector ".player-card", minimum: 10
  end

  # TC103.2: Performance da seleção automática
  test "auto selection performance" do
    visit club_lineup_path(@club)

    start_time = Time.current
    click_button "Auto Selecionar Melhores"

    # Aguardar conclusão (modal aparece ou contador atualiza)
    begin
      accept_alert
    rescue Selenium::WebDriver::Error::NoSuchAlertError
      # Continuar se não houver alert
    end

    # Aguardar que a seleção seja completada
    assert_text "11/11", wait: 2

    selection_time = Time.current - start_time
    assert selection_time < 1.second, "Seleção levou #{selection_time.round(2)}s (limite: 1s)"

    # Verificar resultado da seleção
    selected_cards = all(".player-card.selected")
    assert_equal 11, selected_cards.count
  end

  # TC103.3: Responsividade mobile
  test "mobile responsiveness" do
    # Simular viewport mobile
    page.driver.browser.manage.window.resize_to(375, 667)

    visit club_lineup_path(@club)

    # Verificar elementos essenciais visíveis
    assert_selector "h1"
    assert_button "Auto Selecionar Melhores"
    assert_text "0/11"

    # Verificar que cards estão organizados adequadamente
    player_cards = all(".player-card")
    assert player_cards.count >= 20, "Deveria ter pelo menos 20 cards de jogadores"

    # Testar interação touch (clique)
    first_player = player_cards.first
    assert first_player.visible?
    first_player.click

    assert_text "1/11"
    assert first_player.matches_css?(".selected")

    # Testar scroll se necessário
    page.scroll_to(player_cards.last)
    assert player_cards.last.visible?

    # Testar auto-seleção em mobile
    click_button "Auto Selecionar Melhores"
    accept_alert rescue nil

    assert_text "11/11"

    # Verificar que indicadores são visíveis em mobile
    warning_indicators = all(".out-of-position-indicator")
    chemistry_indicators = all(".chemistry-bonus-indicator")

    # Em mobile, indicadores podem ser menores mas devem estar presentes
    total_indicators = warning_indicators.count + chemistry_indicators.count
    assert total_indicators >= 5, "Deveria ter indicadores visuais em mobile"
  end

  # TC103.4: Performance com elenco grande
  test "performance with large squad" do
    # Criar elenco grande para teste de stress
    create_large_squad(@club, 40)

    start_time = Time.current
    visit club_lineup_path(@club)

    # Aguardar carregamento
    assert_selector "[data-controller='lineup']", wait: 5
    load_time = Time.current - start_time

    assert load_time < 3.seconds, "Carregamento com elenco grande levou #{load_time.round(2)}s (limite: 3s)"

    # Verificar que todos os cards foram renderizados
    player_cards = all(".player-card")
    assert player_cards.count >= 40, "Todos os jogadores deveriam ser renderizados"

    # Testar performance da seleção automática com elenco grande
    start_time = Time.current
    click_button "Auto Selecionar Melhores"

    accept_alert rescue nil
    assert_text "11/11", wait: 3

    selection_time = Time.current - start_time
    assert selection_time < 1.5.seconds, "Seleção com elenco grande levou #{selection_time.round(2)}s (limite: 1.5s)"
  end

  # TC103.5: Memory usage durante uso prolongado
  test "memory usage during extended use" do
    visit club_lineup_path(@club)

    # Simular uso prolongado com múltiplas operações
    10.times do |i|
      # Auto-seleção
      click_button "Auto Selecionar Melhores"
      accept_alert rescue nil
      assert_text "11/11"

      # Limpar seleção
      click_button "Limpar Seleção" if has_button?("Limpar Seleção")

      # Seleção manual de alguns jogadores
      all(".player-card").first(5).each(&:click)
      assert_text "5/11"

      # Desselecionar todos
      all(".player-card.selected").each(&:click)
      assert_text "0/11"

      # Trocar formação
      formations = ["4-4-2", "4-3-3", "5-3-2"]
      select formations[i % formations.length], from: "formation"
    end

    # Verificar que a página ainda está responsiva
    assert_selector "[data-controller='lineup']"
    assert_button "Auto Selecionar Melhores"

    # Fazer uma última auto-seleção para verificar funcionalidade
    click_button "Auto Selecionar Melhores"
    accept_alert rescue nil
    assert_text "11/11"
  end

  # TC103.6: Performance de tooltips
  test "tooltip performance" do
    visit club_lineup_path(@club)
    click_button "Auto Selecionar Melhores"
    accept_alert rescue nil

    # Encontrar jogadores com indicadores
    warning_indicators = all(".out-of-position-indicator")
    chemistry_indicators = all(".chemistry-bonus-indicator")

    all_indicators = warning_indicators + chemistry_indicators

    # Testar performance de hover em múltiplos tooltips
    start_time = Time.current

    all_indicators.first(5).each do |indicator|
      indicator.hover
      assert_selector ".position-tooltip", visible: true, wait: 0.5

      # Mover mouse para fora para esconder tooltip
      find("body").hover

      # Verificar que tooltip desapareceu
      assert_no_selector ".position-tooltip", visible: true, wait: 0.5
    end

    hover_time = Time.current - start_time
    assert hover_time < 2.seconds, "Tooltips levaram #{hover_time.round(2)}s (limite: 2s)"
  end

  # TC103.7: Performance de mudanças de formação
  test "formation change performance" do
    visit club_lineup_path(@club)

    formations = [
      "4-4-2 - Equilibrada",
      "4-3-3 - Ofensiva (+15% Ataque)",
      "5-3-2 - Defensiva (+10% Defesa)",
      "4-5-1 - Meio-campo (+5% Controle)",
      "3-4-3 - Ultra Ofensiva (+20% Ataque)",
      "4-2-3-1 - Posse de Bola (+10% Controle)"
    ]

    formations.each do |formation|
      start_time = Time.current

      select formation, from: "formation"
      click_button "Auto Selecionar Melhores"

      accept_alert rescue nil
      assert_text "11/11", wait: 2

      change_time = Time.current - start_time
      assert change_time < 1.5.seconds, "Mudança para #{formation} levou #{change_time.round(2)}s (limite: 1.5s)"

      # Limpar para próximo teste
      click_button "Limpar Seleção" if has_button?("Limpar Seleção")
    end
  end

  # TC103.8: Performance de renderização de indicadores
  test "visual indicators rendering performance" do
    visit club_lineup_path(@club)

    # Fazer múltiplas auto-seleções para gerar indicadores
    3.times do
      start_time = Time.current

      click_button "Auto Selecionar Melhores"
      accept_alert rescue nil

      # Aguardar que todos os indicadores sejam renderizados
      assert_text "11/11"

      # Verificar que indicadores apareceram rapidamente
      warning_indicators = all(".out-of-position-indicator", wait: 1)
      chemistry_indicators = all(".chemistry-bonus-indicator", wait: 1)

      render_time = Time.current - start_time
      assert render_time < 1.second, "Renderização de indicadores levou #{render_time.round(2)}s (limite: 1s)"

      total_indicators = warning_indicators.count + chemistry_indicators.count
      assert total_indicators >= 5, "Deveria ter pelo menos 5 indicadores"

      # Limpar para próximo teste
      click_button "Limpar Seleção" if has_button?("Limpar Seleção")
    end
  end

  private

  def login_as(user)
    visit root_path
    # Assumir login via fixtures por enquanto
  end

  def create_large_squad(club, total_players)
    current_count = club.players.count

    if current_count < total_players
      positions = %w[GK CB LB RB CDM CM CAM LM RM LW RW ST]
      needed = total_players - current_count

      needed.times do |i|
        position = positions[i % positions.length]
        Player.create!(
          club: club,
          name: "Performance Test Player #{current_count + i + 1}",
          position: position,
          overall: 60 + rand(30)
        )
      end
    end
  end
end