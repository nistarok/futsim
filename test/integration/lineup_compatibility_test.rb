# Test: TEST-INT-003 - Sistema de Compatibilidade
# Objetivo: Validar matriz de compatibilidade e penalidades

require 'test_helper'

class LineupCompatibilityTest < ActionDispatch::IntegrationTest
  def setup
    @club = clubs(:fluminense)
    @user = users(:admin)
    login_as @user
  end

  # TC003.1: Compatibilidade básica
  test "position compatibility matrix" do
    # Arrange: Jogador CDM, precisa de CB
    cdm_player = create_test_player(@club, 'CDM', 80)

    # Act: Sistema calcula compatibilidade CDM → CB
    post club_lineup_path(@club), params: {
      action: 'calculate_compatibility',
      player_id: cdm_player.id,
      target_position: 'CB'
    }, xhr: true

    # Assert: Penalidade de -3 aplicada corretamente
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal -3, response_data['penalty']
    assert_equal 77, response_data['adjusted_overall'] # 80 - 3
    assert response_data['compatible']
  end

  # TC003.2: Penalidades por distância
  test "penalty by position distance" do
    base_overall = 80
    test_cases = [
      { from: 'CM', to: 'CDM', expected_penalty: -2 }, # Posições muito similares
      { from: 'CB', to: 'CDM', expected_penalty: -3 }, # Posições compatíveis
      { from: 'LB', to: 'CB', expected_penalty: -4 },  # Posições relacionadas
      { from: 'LB', to: 'LM', expected_penalty: -3 },  # Lateral para ponta
      { from: 'GK', to: 'ST', expected_penalty: -8 },  # Incompatível total
    ]

    test_cases.each do |test_case|
      player = create_test_player(@club, test_case[:from], base_overall)

      post club_lineup_path(@club), params: {
        action: 'calculate_compatibility',
        player_id: player.id,
        target_position: test_case[:to]
      }, xhr: true

      assert_response :success
      response_data = JSON.parse(response.body)

      assert_equal test_case[:expected_penalty], response_data['penalty'],
        "Penalidade incorreta para #{test_case[:from]} → #{test_case[:to]}"

      expected_overall = base_overall + test_case[:expected_penalty]
      assert_equal expected_overall, response_data['adjusted_overall']

      player.destroy! # Limpar para próximo teste
    end
  end

  # TC003.3: Fallback em cascata
  test "cascading position fallback" do
    # Arrange: Sem jogadores na posição ideal (CB), mas com compatíveis
    @club.players.where(position: 'CB').destroy_all

    # Criar jogadores em posições compatíveis
    cdm_player = create_test_player(@club, 'CDM', 82) # Penalty -3
    lb_player = create_test_player(@club, 'LB', 78)   # Penalty -4
    cm_player = create_test_player(@club, 'CM', 75)   # Penalty -5

    # Act: Sistema busca CB para formação 4-4-2
    post club_lineup_path(@club), params: {
      action: 'find_best_for_position',
      target_position: 'CB',
      formation: '4-4-2'
    }, xhr: true

    # Assert: Melhor alternativa selecionada (CDM com menor penalidade)
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal cdm_player.id, response_data['best_player']['id']
    assert_equal -3, response_data['best_player']['penalty']
    assert_equal 79, response_data['best_player']['adjusted_overall']
    assert_equal 'CDM', response_data['best_player']['original_position']
  end

  # TC003.4: Matriz completa de posições
  test "complete compatibility matrix" do
    compatibility_matrix = {
      'GK' => { 'GK' => 0 }, # Goleiro só pode jogar de goleiro
      'CB' => { 'CB' => 0, 'CDM' => -3, 'LB' => -5, 'RB' => -5 },
      'LB' => { 'LB' => 0, 'CB' => -4, 'LM' => -3, 'CM' => -6 },
      'RB' => { 'RB' => 0, 'CB' => -4, 'RM' => -3, 'CM' => -6 },
      'CDM' => { 'CDM' => 0, 'CB' => -3, 'CM' => -2 },
      'CM' => { 'CM' => 0, 'CDM' => -2, 'CAM' => -2, 'LM' => -4, 'RM' => -4 },
      'CAM' => { 'CAM' => 0, 'CM' => -2, 'LW' => -4, 'RW' => -4, 'ST' => -5 },
      'LM' => { 'LM' => 0, 'LB' => -3, 'CM' => -4, 'LW' => -3 },
      'RM' => { 'RM' => 0, 'RB' => -3, 'CM' => -4, 'RW' => -3 },
      'LW' => { 'LW' => 0, 'LM' => -3, 'CAM' => -4, 'ST' => -4 },
      'RW' => { 'RW' => 0, 'RM' => -3, 'CAM' => -4, 'ST' => -4 },
      'ST' => { 'ST' => 0, 'CAM' => -5, 'LW' => -4, 'RW' => -4 }
    }

    compatibility_matrix.each do |from_pos, compatible_positions|
      player = create_test_player(@club, from_pos, 80)

      compatible_positions.each do |to_pos, expected_penalty|
        post club_lineup_path(@club), params: {
          action: 'calculate_compatibility',
          player_id: player.id,
          target_position: to_pos
        }, xhr: true

        assert_response :success
        response_data = JSON.parse(response.body)

        assert_equal expected_penalty, response_data['penalty'],
          "Matriz incorreta: #{from_pos} → #{to_pos}"
      end

      player.destroy!
    end
  end

  # TC003.5: Compatibilidade com química
  test "compatibility with chemistry bonus" do
    # Arrange: Jogador CDM com stats ideais para CB (defense alta)
    cdm_player = create_test_player(@club, 'CDM', 80, {
      defense: 85,  # Alto defense para CB
      strength: 80  # Força adequada
    })

    # Act: Calcular compatibilidade CDM → CB com chemistry
    post club_lineup_path(@club), params: {
      action: 'calculate_advanced_compatibility',
      player_id: cdm_player.id,
      target_position: 'CB'
    }, xhr: true

    # Assert: Penalidade base -3, mas com bônus de química
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal -3, response_data['base_penalty']
    assert response_data['chemistry_bonus'] > 0
    assert response_data['adjusted_penalty'] > response_data['base_penalty'] # Penalidade reduzida
    assert response_data['final_overall'] > 77 # Melhor que apenas penalty
  end

  # TC003.6: Posições incompatíveis
  test "incompatible positions" do
    # Arrange: Goleiro tentando jogar de atacante
    gk_player = create_test_player(@club, 'GK', 80)

    # Act: Tentar compatibilidade GK → ST
    post club_lineup_path(@club), params: {
      action: 'calculate_compatibility',
      player_id: gk_player.id,
      target_position: 'ST'
    }, xhr: true

    # Assert: Penalidade máxima aplicada
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal -8, response_data['penalty'] # Penalidade máxima
    assert_equal 72, response_data['adjusted_overall']
    assert_not response_data['recommended'] # Não recomendado
  end

  # TC003.7: Otimização de compatibilidade
  test "compatibility optimization" do
    # Arrange: Múltiplos jogadores para mesma posição-alvo
    players_data = [
      { position: 'CDM', overall: 82, penalty: -3 }, # 79 final
      { position: 'LB', overall: 80, penalty: -4 },  # 76 final
      { position: 'CM', overall: 78, penalty: -5 }   # 73 final
    ]

    players = players_data.map do |data|
      create_test_player(@club, data[:position], data[:overall])
    end

    # Act: Encontrar melhor opção para CB
    post club_lineup_path(@club), params: {
      action: 'optimize_position_compatibility',
      target_position: 'CB',
      player_ids: players.map(&:id)
    }, xhr: true

    # Assert: CDM selecionado (melhor overall ajustado)
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal players.first.id, response_data['best_option']['player_id'] # CDM
    assert_equal 79, response_data['best_option']['adjusted_overall']
    assert_equal -3, response_data['best_option']['penalty']
  end

  # TC003.8: Cache de compatibilidade
  test "compatibility calculation caching" do
    player = create_test_player(@club, 'CM', 80)

    # Primeira chamada
    start_time = Time.current
    post club_lineup_path(@club), params: {
      action: 'calculate_compatibility',
      player_id: player.id,
      target_position: 'CDM'
    }, xhr: true
    first_call_time = Time.current - start_time

    assert_response :success

    # Segunda chamada (deve ser mais rápida com cache)
    start_time = Time.current
    post club_lineup_path(@club), params: {
      action: 'calculate_compatibility',
      player_id: player.id,
      target_position: 'CDM'
    }, xhr: true
    second_call_time = Time.current - start_time

    assert_response :success
    assert second_call_time < first_call_time, "Cache não funcionando"
  end

  private

  def login_as(user)
    post session_path, params: { user_id: user.id }
  end

  def create_test_player(club, position, overall, additional_stats = {})
    base_stats = {
      club: club,
      name: "Test #{position} #{rand(1000)}",
      position: position,
      overall: overall
    }

    Player.create!(base_stats.merge(additional_stats))
  end
end