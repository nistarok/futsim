# Test: TEST-INT-005 - Sistema de Química
# Objetivo: Validar cálculos de química e bônus por atributos

require 'test_helper'

class LineupChemistryTest < ActionDispatch::IntegrationTest
  def setup
    @club = clubs(:fluminense)
    @user = users(:admin)
    login_as @user
  end

  # TC005.1: Cálculo de adequação
  test "stat match calculation" do
    # Arrange: Jogador com stats específicos
    player = create_chemistry_player(@club, 'ST', {
      attack: 85,    # 85% do ideal (100)
      speed: 75,     # 75% do ideal (100)
      strength: 70   # 70% do ideal (100)
    })

    # Act: Calcular adequação para posição ST
    post club_lineup_path(@club), params: {
      action: 'calculate_stat_match',
      player_id: player.id,
      target_position: 'ST'
    }, xhr: true

    # Assert: Ratio de adequação correto
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_in_delta 0.766, response_data['stat_match_ratio'], 0.01 # (85*0.5 + 75*0.3 + 70*0.2)/100
    assert_equal 'good', response_data['adequacy_level']
    assert response_data['suitable_for_position']
  end

  # TC005.2: Bônus de química
  test "chemistry bonus application" do
    # Arrange: Jogador ideal para posição (stats 80%+)
    ideal_cb = create_chemistry_player(@club, 'CB', {
      defense: 90,   # Excelente defesa
      strength: 85,  # Boa força
      stamina: 80    # Boa resistência
    })

    # Act: Sistema calcula química para CB
    post club_lineup_path(@club), params: {
      action: 'calculate_chemistry_bonus',
      player_id: ideal_cb.id,
      target_position: 'CB'
    }, xhr: true

    # Assert: Bônus de +2 aplicado
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_in_delta 0.85, response_data['stat_match_ratio'], 0.02 # Stats altos
    assert_equal 2, response_data['chemistry_bonus']
    assert_equal 'excellent', response_data['chemistry_level']
    assert_equal 82, response_data['boosted_overall'] # 80 base + 2 bonus
  end

  # TC005.3: Redução de penalidade
  test "penalty reduction with good stats" do
    # Arrange: Jogador fora de posição mas com stats adequados
    versatile_player = create_chemistry_player(@club, 'CDM', {
      defense: 82,   # Alto defense (bom para CB)
      strength: 78,  # Boa força
      stamina: 85,   # Excelente stamina
      overall: 80
    })

    # Act: Sistema calcula penalidade CDM → CB com chemistry
    post club_lineup_path(@club), params: {
      action: 'calculate_advanced_compatibility',
      player_id: versatile_player.id,
      target_position: 'CB'
    }, xhr: true

    # Assert: Penalidade reduzida em 1 ponto
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal -3, response_data['base_penalty'] # CDM → CB
    assert_equal 1, response_data['chemistry_bonus']
    assert_equal -2, response_data['final_penalty'] # -3 + 1 (redução)
    assert_equal 78, response_data['final_overall'] # 80 - 2
    assert response_data['penalty_reduced']
  end

  # TC005.4: Adequação por posição específica
  test "position specific stat requirements" do
    position_tests = [
      {
        position: 'GK',
        stats: { goalkeeping: 90, reflexes: 85 },
        expected_ratio: 0.87 # (90*0.6 + 85*0.4)/100
      },
      {
        position: 'ST',
        stats: { attack: 85, speed: 80, strength: 75 },
        expected_ratio: 0.815 # (85*0.5 + 80*0.3 + 75*0.2)/100
      },
      {
        position: 'CM',
        stats: { passing: 85, stamina: 80, attack: 70, defense: 75 },
        expected_ratio: 0.80 # (85*0.4 + 80*0.3 + 70*0.15 + 75*0.15)/100
      }
    ]

    position_tests.each do |test_case|
      player = create_chemistry_player(@club, test_case[:position], test_case[:stats])

      post club_lineup_path(@club), params: {
        action: 'calculate_stat_match',
        player_id: player.id,
        target_position: test_case[:position]
      }, xhr: true

      assert_response :success
      response_data = JSON.parse(response.body)

      assert response_data['success']
      assert_in_delta test_case[:expected_ratio], response_data['stat_match_ratio'], 0.02,
        "Ratio incorreto para #{test_case[:position]}"

      player.destroy!
    end
  end

  # TC005.5: Escalas de bônus de química
  test "chemistry bonus scales" do
    bonus_tests = [
      { stat_ratio: 0.85, expected_bonus: 2, level: 'excellent' },
      { stat_ratio: 0.70, expected_bonus: 1, level: 'good' },
      { stat_ratio: 0.55, expected_bonus: 0, level: 'adequate' },
      { stat_ratio: 0.40, expected_bonus: -1, level: 'poor' }
    ]

    bonus_tests.each do |test_case|
      # Arrange: Player com stat ratio específico para ST
      stats_for_ratio = calculate_stats_for_ratio(test_case[:stat_ratio])
      player = create_chemistry_player(@club, 'ST', stats_for_ratio)

      # Act: Calcular bônus
      post club_lineup_path(@club), params: {
        action: 'calculate_chemistry_bonus',
        player_id: player.id,
        target_position: 'ST'
      }, xhr: true

      # Assert: Bônus correto
      assert_response :success
      response_data = JSON.parse(response.body)

      assert response_data['success']
      assert_equal test_case[:expected_bonus], response_data['chemistry_bonus'],
        "Bônus incorreto para ratio #{test_case[:stat_ratio]}"
      assert_equal test_case[:level], response_data['chemistry_level']

      player.destroy!
    end
  end

  # TC005.6: Priorização por química na seleção
  test "chemistry prioritization in selection" do
    # Arrange: Múltiplos jogadores CB com diferentes químicas
    players = [
      create_chemistry_player(@club, 'CB', { defense: 90, strength: 85, stamina: 80, overall: 78 }), # Alta química, overall baixo
      create_chemistry_player(@club, 'CB', { defense: 70, strength: 65, stamina: 60, overall: 85 }), # Baixa química, overall alto
      create_chemistry_player(@club, 'CB', { defense: 85, strength: 80, stamina: 75, overall: 80 })  # Equilibrado
    ]

    # Act: Auto-seleção priorizando química
    post club_lineup_path(@club), params: {
      action: 'auto_select',
      formation: '5-3-2', # Precisa 3 CBs
      prioritize_chemistry: true
    }, xhr: true

    # Assert: Jogadores com melhor química selecionados
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    selected_cbs = response_data['selected_players_by_position']['CB']
    assert_equal 3, selected_cbs.length

    # Verificar que jogadores com alta química foram priorizados
    high_chemistry_player = selected_cbs.find { |p| p['player_id'] == players[0].id }
    equilibrated_player = selected_cbs.find { |p| p['player_id'] == players[2].id }

    assert high_chemistry_player, "Jogador com alta química deveria ser selecionado"
    assert equilibrated_player, "Jogador equilibrado deveria ser selecionado"
  end

  # TC005.7: Cache de cálculos de química
  test "chemistry calculation caching" do
    player = create_chemistry_player(@club, 'CM', {
      passing: 85, stamina: 80, attack: 75, defense: 70
    })

    # Primeira chamada
    start_time = Time.current
    post club_lineup_path(@club), params: {
      action: 'calculate_chemistry_bonus',
      player_id: player.id,
      target_position: 'CM'
    }, xhr: true
    first_time = Time.current - start_time

    assert_response :success

    # Segunda chamada (cache)
    start_time = Time.current
    post club_lineup_path(@club), params: {
      action: 'calculate_chemistry_bonus',
      player_id: player.id,
      target_position: 'CM'
    }, xhr: true
    cached_time = Time.current - start_time

    assert_response :success
    assert cached_time < first_time, "Cache de química não funcionando"
  end

  # TC005.8: Indicadores visuais de química
  test "chemistry visual indicators" do
    # Arrange: Jogadores com diferentes níveis de química
    excellent_player = create_chemistry_player(@club, 'ST', { attack: 90, speed: 85, strength: 80 })
    poor_player = create_chemistry_player(@club, 'ST', { attack: 50, speed: 45, strength: 40 })

    # Act: Selecionar jogadores e verificar indicadores
    post club_lineup_path(@club), params: {
      action: 'toggle_player',
      player_id: excellent_player.id
    }, xhr: true

    assert_response :success
    excellent_response = JSON.parse(response.body)

    post club_lineup_path(@club), params: {
      action: 'toggle_player',
      player_id: poor_player.id
    }, xhr: true

    assert_response :success
    poor_response = JSON.parse(response.body)

    # Assert: Indicadores visuais corretos
    assert excellent_response['chemistry_indicator']
    assert_equal '✨', excellent_response['chemistry_icon']
    assert_includes excellent_response['css_classes'], 'chemistry-excellent'

    assert_not poor_response['chemistry_indicator']
    assert_includes poor_response['css_classes'], 'chemistry-poor'
  end

  private

  def login_as(user)
    post session_path, params: { user_id: user.id }
  end

  def create_chemistry_player(club, position, stats)
    base_attributes = {
      club: club,
      name: "Chemistry Test #{position} #{rand(1000)}",
      position: position,
      overall: stats[:overall] || 80
    }

    # Remover overall dos stats para não duplicar
    player_stats = stats.except(:overall)

    Player.create!(base_attributes.merge(player_stats))
  end

  def calculate_stats_for_ratio(target_ratio)
    # Para posição ST: attack: 0.5, speed: 0.3, strength: 0.2
    # Calcular stats que resultem no ratio desejado
    base_value = target_ratio * 100

    {
      attack: (base_value * 0.5 / 0.5).round,      # 50% do peso
      speed: (base_value * 0.3 / 0.3).round,       # 30% do peso
      strength: (base_value * 0.2 / 0.2).round     # 20% do peso
    }
  end
end