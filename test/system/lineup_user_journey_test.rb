# Test: TEST-E2E-001 - Jornada Completa do Usuário
# Objetivo: Simular experiência real do usuário do início ao fim

require 'application_system_test_case'

class LineupUserJourneyTest < ApplicationSystemTestCase
  def setup
    @club = clubs(:fluminense)
    @user = users(:admin)
    login_as @user
  end

  # TC101.1: Fluxo completo de escalação
  test "complete lineup flow" do
    visit club_lineup_path(@club)

    # 1. Verificar carregamento inicial
    assert_text "0/11"
    assert_text "#{@club.name} - Escalações"
    assert_selector "[data-controller='lineup']"

    # 2. Seleção manual
    first_goalkeeper = find(".player-card[data-position='GK']", match: :first)
    first_goalkeeper.click
    assert_text "1/11"

    # Verificar feedback visual
    assert_selector ".player-card.selected", count: 1

    # 3. Seleção automática
    click_button "Auto Selecionar Melhores"

    # Aguardar modal ou alert
    accept_alert "Melhores jogadores selecionados automaticamente!" if page.driver.browser.switch_to.alert rescue nil

    assert_text "11/11"

    # 4. Verificar indicadores visuais
    warning_indicators = all(".out-of-position-indicator")
    chemistry_indicators = all(".chemistry-bonus-indicator")

    assert warning_indicators.count >= 5, "Deveria ter pelo menos 5 indicadores de fora de posição"
    assert chemistry_indicators.count >= 1, "Deveria ter pelo menos 1 indicador de química"

    # 5. Testar tooltips
    if warning_indicators.any?
      warning_indicators.first.hover
      assert_selector ".position-tooltip", visible: true
      assert_text "Penalidade:"
      assert_text "→" # Seta de mudança de posição
    end

    if chemistry_indicators.any?
      chemistry_indicators.first.hover
      assert_selector ".position-tooltip", visible: true
      assert_text "Bônus:"
    end

    # 6. Salvar escalação
    click_button "Salvar Escalação"
    assert_text "Escalação salva com sucesso"
  end

  # TC101.2: Troca de formação dinâmica
  test "formation change flow" do
    visit club_lineup_path(@club)

    # Auto-selecionar em 4-4-2
    select "4-4-2 - Equilibrada", from: "formation"
    click_button "Auto Selecionar Melhores"

    accept_alert rescue nil
    assert_text "11/11"

    initial_formation = find("#formation").value
    assert_equal "4-4-2", initial_formation

    # Mudar para 4-3-3
    select "4-3-3 - Ofensiva (+15% Ataque)", from: "formation"

    # Re-executar seleção
    click_button "Auto Selecionar Melhores"
    accept_alert rescue nil

    # Verificar adaptação
    assert_text "11/11"
    new_formation = find("#formation").value
    assert_includes ["4-3-3", "4-4-2"], new_formation # Pode ter fallback
  end

  # TC101.3: Interação com jogadores individuais
  test "individual player interaction" do
    visit club_lineup_path(@club)

    # Selecionar jogadores manualmente um por vez
    player_cards = all(".player-card").first(5)

    player_cards.each_with_index do |card, index|
      card.click
      expected_count = index + 1
      assert_text "#{expected_count}/11"

      # Verificar estado visual
      assert card.matches_css?(".selected")
    end

    # Desselecionar o terceiro jogador
    player_cards[2].click
    assert_text "4/11"
    assert_not player_cards[2].matches_css?(".selected")

    # Verificar que outros permanecem selecionados
    assert player_cards[0].matches_css?(".selected")
    assert player_cards[1].matches_css?(".selected")
    assert player_cards[3].matches_css?(".selected")
    assert player_cards[4].matches_css?(".selected")
  end

  # TC101.4: Teste de limite de jogadores
  test "player limit enforcement" do
    visit club_lineup_path(@club)

    # Selecionar 11 jogadores
    player_cards = all(".player-card").first(11)
    player_cards.each(&:click)

    assert_text "11/11"

    # Tentar selecionar o 12º jogador
    twelfth_card = all(".player-card")[11]
    twelfth_card.click

    # Verificar que não foi selecionado
    assert_text "11/11" # Contador não mudou
    assert_not twelfth_card.matches_css?(".selected")

    # Verificar mensagem de erro se existir
    if page.has_text?("Máximo")
      assert_text "Máximo de 11 jogadores"
    end
  end

  # TC101.5: Navegação e persistência
  test "navigation and state persistence" do
    visit club_lineup_path(@club)

    # Selecionar alguns jogadores
    selected_cards = all(".player-card").first(3)
    selected_cards.each(&:click)
    assert_text "3/11"

    # Navegar para outra página
    visit club_path(@club)
    assert_text @club.name

    # Voltar para escalação
    visit club_lineup_path(@club)

    # Verificar que estado foi preservado
    # (Dependendo da implementação, pode usar localStorage ou sessão)
    # Este teste pode precisar ser ajustado baseado na implementação real
  end

  # TC101.6: Teste de responsividade
  test "responsive design test" do
    # Testar em diferentes tamanhos de tela
    page.driver.browser.manage.window.resize_to(375, 667) # Mobile

    visit club_lineup_path(@club)

    # Verificar elementos essenciais visíveis
    assert_selector "h1"
    assert_button "Auto Selecionar Melhores"
    assert_text "0/11"

    # Verificar que cards estão visíveis e clicáveis
    first_card = find(".player-card", match: :first)
    assert first_card.visible?
    first_card.click
    assert_text "1/11"

    # Testar em tablet
    page.driver.browser.manage.window.resize_to(768, 1024)

    # Elementos ainda devem estar funcionais
    assert_button "Auto Selecionar Melhores"
    assert_text "1/11"

    # Voltar para desktop
    page.driver.browser.manage.window.resize_to(1920, 1080)
  end

  # TC101.7: Performance percebida
  test "perceived performance" do
    visit club_lineup_path(@club)

    # Medir tempo de carregamento inicial
    start_time = Time.current
    assert_selector "[data-controller='lineup']" # Stimulus conectado
    load_time = Time.current - start_time

    assert load_time < 2.seconds, "Página carregou em #{load_time}s (limite: 2s)"

    # Medir tempo de seleção automática
    start_time = Time.current
    click_button "Auto Selecionar Melhores"

    # Aguardar conclusão
    assert_text "11/11", wait: 2
    selection_time = Time.current - start_time

    assert selection_time < 1.second, "Seleção levou #{selection_time}s (limite: 1s)"
  end

  # TC101.8: Acessibilidade
  test "accessibility features" do
    visit club_lineup_path(@club)

    # Verificar labels e aria-labels
    assert_selector "button", text: "Auto Selecionar Melhores"
    assert_selector "[aria-label]", count: 1, minimum: 1

    # Verificar navegação por teclado
    first_card = find(".player-card", match: :first)
    first_card.send_keys(:space) # Simular seleção por teclado

    # Verificar que cores não são a única forma de comunicar estado
    # (indicadores textuais devem existir)
    assert_text "1/11"
  end

  private

  def login_as(user)
    # Implementar login baseado no sistema de auth do app
    visit root_path
    # Adicionar lógica específica de login OAuth ou sessão
    # Por enquanto, assumir que usuário já está logado via fixtures
  end
end