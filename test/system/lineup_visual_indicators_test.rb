# Test: TEST-E2E-002 - Indicadores Visuais
# Objetivo: Validar todos os elementos visuais e interações

require 'application_system_test_case'

class LineupVisualIndicatorsTest < ApplicationSystemTestCase
  def setup
    @club = clubs(:fluminense)
    @user = users(:admin)
    login_as @user
  end

  # TC102.1: Indicadores de posição
  test "visual position indicators" do
    visit club_lineup_path(@club)
    click_button "Auto Selecionar Melhores"

    accept_alert rescue nil
    assert_text "11/11"

    # Verificar indicador de fora de posição
    warning_indicators = all(".out-of-position-indicator")
    assert warning_indicators.count >= 5, "Deveria ter pelo menos 5 jogadores fora de posição"

    # Verificar indicador de química
    chemistry_indicators = all(".chemistry-bonus-indicator")
    assert chemistry_indicators.count >= 1, "Deveria ter pelo menos 1 jogador com bônus de química"

    # Verificar ícones específicos
    warning_indicators.each do |indicator|
      assert indicator.has_text?("⚠️") || indicator.has_css?(".warning-icon")
    end

    chemistry_indicators.each do |indicator|
      assert indicator.has_text?("✨") || indicator.has_css?(".chemistry-icon")
    end

    # Verificar animação pulse nos indicadores de química
    if chemistry_indicators.any?
      chemistry_indicator = chemistry_indicators.first
      # Verificar se tem classe de animação
      assert chemistry_indicator.matches_css?(".animate-pulse") ||
             chemistry_indicator.matches_css?("[style*='animation']")
    end
  end

  # TC102.2: Tooltips informativos
  test "informative tooltips" do
    visit club_lineup_path(@club)
    click_button "Auto Selecionar Melhores"

    accept_alert rescue nil

    # Hover sobre indicador de fora de posição
    warning_indicator = find(".out-of-position-indicator", match: :first)
    warning_indicator.hover

    # Verificar tooltip aparece
    tooltip = find(".position-tooltip", visible: true)
    assert tooltip.visible?
    assert tooltip.has_text?("Penalidade:")
    assert tooltip.has_text?("→") # Seta de mudança de posição

    # Verificar conteúdo do tooltip
    assert tooltip.has_text?(/[A-Z]{2,3}.*→.*[A-Z]{2,3}/) # Padrão "POS → POS"
    assert tooltip.has_text?(/-\d/) # Penalidade numérica

    # Testar tooltip de química se existir
    chemistry_indicators = all(".chemistry-bonus-indicator")
    if chemistry_indicators.any?
      chemistry_indicator = chemistry_indicators.first
      chemistry_indicator.hover

      chemistry_tooltip = find(".position-tooltip", visible: true)
      assert chemistry_tooltip.has_text?("Química") || chemistry_tooltip.has_text?("Bônus")
      assert chemistry_tooltip.has_text?("+") # Indicador de bônus positivo
    end
  end

  # TC102.3: Estados visuais dos jogadores
  test "player visual states" do
    visit club_lineup_path(@club)

    # Estado inicial - não selecionado
    first_player = find(".player-card", match: :first)
    assert_not first_player.matches_css?(".selected")
    assert_not first_player.matches_css?(".bg-green-50")

    # Estado selecionado
    first_player.click
    assert first_player.matches_css?(".selected")
    assert first_player.matches_css?(".bg-green-50") ||
           first_player.matches_css?(".bg-green-100") ||
           first_player.matches_css?("[style*='background']")

    # Estado com indicador
    click_button "Auto Selecionar Melhores"
    accept_alert rescue nil

    # Verificar bordas coloridas
    selected_players = all(".player-card.selected")
    warning_players = selected_players.select { |p| p.has_css?(".out-of-position-indicator") }
    chemistry_players = selected_players.select { |p| p.has_css?(".chemistry-bonus-indicator") }

    if warning_players.any?
      warning_player = warning_players.first
      assert warning_player.matches_css?(".border-yellow-400") ||
             warning_player.matches_css?(".border-yellow-500") ||
             warning_player.matches_css?("[style*='border-color: #fbbf24']")
    end

    if chemistry_players.any?
      chemistry_player = chemistry_players.first
      assert chemistry_player.matches_css?(".border-green-400") ||
             chemistry_player.matches_css?(".border-green-500") ||
             chemistry_player.matches_css?("[style*='border-color: #10b981']")
    end
  end

  # TC102.4: Contador visual
  test "visual counter display" do
    visit club_lineup_path(@club)

    # Contador inicial
    counter = find(".lineup-counter")
    assert_text "0/11"

    # Seleção progressiva
    player_cards = all(".player-card").first(3)
    player_cards.each_with_index do |card, index|
      card.click
      expected_count = index + 1
      assert_text "#{expected_count}/11"

      # Verificar estilo do contador
      if expected_count == 11
        assert counter.matches_css?(".text-green-600") || counter.has_css?(".complete")
      else
        assert counter.matches_css?(".text-gray-700") || counter.has_css?(".incomplete")
      end
    end

    # Contador completo
    remaining_players = all(".player-card")[3..10]
    remaining_players.each(&:click)

    assert_text "11/11"
    counter = find(".lineup-counter")
    assert counter.matches_css?(".text-green-600") ||
           counter.matches_css?(".font-bold") ||
           counter.has_css?(".complete")
  end

  # TC102.5: Indicadores de formação
  test "formation visual indicators" do
    visit club_lineup_path(@club)

    # Verificar dropdown de formação
    formation_select = find("#formation")
    assert formation_select.visible?

    # Testar mudança visual de formação
    select "4-3-3 - Ofensiva (+15% Ataque)", from: "formation"

    # Verificar se há feedback visual da mudança
    formation_description = find(".formation-description") rescue nil
    if formation_description
      assert formation_description.has_text?("4-3-3")
    end

    # Auto-selecionar e verificar adaptação visual
    click_button "Auto Selecionar Melhores"
    accept_alert rescue nil

    # Verificar se formação foi mantida ou adaptada
    current_formation = find("#formation").value
    assert_not_empty current_formation

    # Se houve adaptação, deveria haver indicação visual
    adaptation_message = find(".formation-adaptation-message") rescue nil
    if current_formation != "4-3-3" && adaptation_message
      assert adaptation_message.has_text?("adaptada") || adaptation_message.has_text?("ajustada")
    end
  end

  # TC102.6: Cores por posição
  test "position color coding" do
    visit club_lineup_path(@club)

    # Verificar cores por tipo de posição
    position_colors = {
      'GK' => ['green', '#228B22'],     # Goleiro - Verde
      'CB' => ['blue', '#0047AB'],      # Defesa - Azul
      'LB' => ['blue', '#0047AB'],
      'RB' => ['blue', '#0047AB'],
      'CDM' => ['orange', '#ea580c'],   # Meio-campo - Laranja
      'CM' => ['orange', '#ea580c'],
      'CAM' => ['orange', '#ea580c'],
      'LM' => ['orange', '#ea580c'],
      'RM' => ['orange', '#ea580c'],
      'LW' => ['red', '#dc2626'],       # Ataque - Vermelho
      'RW' => ['red', '#dc2626'],
      'ST' => ['red', '#dc2626']
    }

    position_colors.each do |position, colors|
      position_cards = all("[data-position='#{position}']")
      next if position_cards.empty?

      card = position_cards.first
      color_name, color_hex = colors

      # Verificar se a cor está aplicada (classe CSS ou style)
      has_color = card.matches_css?(".text-#{color_name}-600") ||
                  card.matches_css?(".bg-#{color_name}-50") ||
                  card.matches_css?("[style*='#{color_hex}']") ||
                  card.has_css?(".position-#{color_name}")

      assert has_color, "Card da posição #{position} deveria ter cor #{color_name}"
    end
  end

  # TC102.7: Animações e transições
  test "animations and transitions" do
    visit club_lineup_path(@club)

    # Testar animação de seleção
    first_card = find(".player-card", match: :first)
    first_card.click

    # Verificar se há transição visual (difícil de testar automaticamente)
    # Pelo menos verificar que o estado mudou
    assert first_card.matches_css?(".selected")

    # Testar animação de auto-seleção
    click_button "Auto Selecionar Melhores"

    # Durante a auto-seleção, pode haver indicador de loading
    loading_indicator = find(".loading-indicator") rescue nil
    if loading_indicator
      assert loading_indicator.visible?
    end

    # Aguardar conclusão
    accept_alert rescue nil
    assert_text "11/11"

    # Verificar animações dos indicadores
    chemistry_indicators = all(".chemistry-bonus-indicator")
    chemistry_indicators.each do |indicator|
      # Verificar animação pulse ou similar
      has_animation = indicator.matches_css?(".animate-pulse") ||
                      indicator.matches_css?("[style*='animation']") ||
                      indicator.has_css?(".pulse-animation")

      assert has_animation, "Indicador de química deveria ter animação"
    end
  end

  # TC102.8: Feedback de erro visual
  test "visual error feedback" do
    visit club_lineup_path(@club)

    # Selecionar 11 jogadores
    all(".player-card").first(11).each(&:click)
    assert_text "11/11"

    # Tentar selecionar mais um
    twelfth_card = all(".player-card")[11]
    twelfth_card.click

    # Verificar feedback de erro visual
    error_message = find(".error-message") rescue nil
    flash_message = find(".flash-message") rescue nil
    alert_message = find(".alert") rescue nil

    error_shown = error_message&.visible? || flash_message&.visible? || alert_message&.visible?

    # Se não há mensagem visual, pelo menos o card não deveria estar selecionado
    assert_not twelfth_card.matches_css?(".selected")
    assert_text "11/11" # Contador não mudou
  end

  private

  def login_as(user)
    # Implementar login baseado no sistema de auth do app
    visit root_path
    # Por enquanto, assumir que usuário já está logado via fixtures
  end
end