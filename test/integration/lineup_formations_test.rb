# Test: TEST-INT-004 - Formações Adaptativas
# Objetivo: Validar sistema de formações com fallback inteligente

require 'test_helper'

class LineupFormationsTest < ActionDispatch::IntegrationTest
  def setup
    @club = clubs(:fluminense)
    @user = users(:admin)
    login_as @user
  end

  # TC004.1: Todas as formações válidas
  test "all formations valid structure" do
    formations = {
      '4-4-2' => { 'GK' => 1, 'CB' => 2, 'LB' => 1, 'RB' => 1, 'CDM' => 2, 'CM' => 2, 'ST' => 2 },
      '4-3-3' => { 'GK' => 1, 'CB' => 2, 'LB' => 1, 'RB' => 1, 'CDM' => 1, 'CM' => 2, 'ST' => 1, 'LW' => 1, 'RW' => 1 },
      '5-3-2' => { 'GK' => 1, 'CB' => 3, 'LB' => 1, 'RB' => 1, 'CM' => 3, 'ST' => 2 },
      '4-5-1' => { 'GK' => 1, 'CB' => 2, 'LB' => 1, 'RB' => 1, 'CDM' => 2, 'CM' => 2, 'CAM' => 1, 'ST' => 1 },
      '3-4-3' => { 'GK' => 1, 'CB' => 3, 'LM' => 1, 'RM' => 1, 'CM' => 2, 'ST' => 1, 'LW' => 1, 'RW' => 1 },
      '4-2-3-1' => { 'GK' => 1, 'CB' => 2, 'LB' => 1, 'RB' => 1, 'CDM' => 2, 'CAM' => 1, 'LW' => 1, 'RW' => 1, 'ST' => 1 }
    }

    formations.each do |formation_name, positions|
      # Act: Validar estrutura da formação
      post club_lineup_path(@club), params: {
        action: 'validate_formation',
        formation: formation_name
      }, xhr: true

      # Assert: Formação soma exatamente 11 jogadores
      assert_response :success
      response_data = JSON.parse(response.body)

      assert response_data['valid']
      assert_equal 11, response_data['total_players']
      assert_equal positions, response_data['position_limits']
      assert_equal formation_name, response_data['formation_name']
    end
  end

  # TC004.2: Viabilidade de formação
  test "formation viability calculation" do
    # Arrange: Elenco com composição específica
    squad_composition = {
      'GK' => 2, 'CB' => 4, 'LB' => 2, 'RB' => 2,
      'CDM' => 2, 'CM' => 4, 'CAM' => 2,
      'LM' => 1, 'RM' => 1, 'LW' => 2, 'RW' => 2, 'ST' => 3
    }

    create_specific_squad(@club, squad_composition)

    formations_to_test = ['4-4-2', '4-3-3', '3-4-3', '5-3-2']

    formations_to_test.each do |formation|
      # Act: Testar viabilidade da formação
      post club_lineup_path(@club), params: {
        action: 'calculate_viability',
        formation: formation
      }, xhr: true

      # Assert: Percentual de viabilidade correto
      assert_response :success
      response_data = JSON.parse(response.body)

      assert response_data.key?('viability_percentage')
      assert response_data['viability_percentage'].between?(0, 100)
      assert response_data.key?('viable')
      assert response_data.key?('missing_positions') if response_data['viability_percentage'] < 100
    end
  end

  # TC004.3: Cadeia de fallback
  test "formation fallback chain" do
    # Arrange: Formação 3-4-3 impossível (sem laterais-meios suficientes)
    create_limited_squad(@club, {
      'GK' => 2, 'CB' => 5, 'LB' => 1, 'RB' => 1,
      'CDM' => 2, 'CM' => 4, 'ST' => 3
    })

    # Act: Sistema executa fallback
    post club_lineup_path(@club), params: {
      action: 'find_best_formation',
      preferred_formation: '3-4-3'
    }, xhr: true

    # Assert: Testa 4-3-3, depois 4-4-2, etc.
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_not_equal '3-4-3', response_data['selected_formation']
    assert response_data['fallback_used']
    assert response_data['fallback_chain'].is_a?(Array)
    assert response_data['fallback_chain'].include?('4-3-3')
    assert response_data['fallback_chain'].include?('4-4-2')
    assert_equal 100, response_data['final_viability']
  end

  # TC004.4: Formação ótima por elenco
  test "optimal formation by squad" do
    # Arrange: Elenco balanceado para 4-3-3
    create_balanced_433_squad(@club)

    # Act: Encontrar formação ótima
    post club_lineup_path(@club), params: {
      action: 'find_optimal_formation'
    }, xhr: true

    # Assert: 4-3-3 selecionada como ótima
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal '4-3-3', response_data['optimal_formation']
    assert response_data['viability_score'] >= 90
    assert response_data['reasoning'].include?('ideal')
  end

  # TC004.5: Adaptação automática
  test "automatic formation adaptation" do
    # Arrange: Elenco que força adaptação
    create_defensive_heavy_squad(@club)

    # Act: Auto-seleção com formação ofensiva
    post club_lineup_path(@club), params: {
      action: 'auto_select',
      formation: '4-3-3'
    }, xhr: true

    # Assert: Formação adaptada para mais defensiva
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 11, response_data['selected_count']
    assert_includes ['5-3-2', '4-5-1'], response_data['formation_used']
    assert response_data['formation_adapted']
    assert response_data['adaptation_reason'].include?('defensivo')
  end

  # TC004.6: Validação de limites por posição
  test "position limits validation" do
    formation_limits = {
      '4-4-2' => { max_defenders: 4, max_midfielders: 4, max_attackers: 2 },
      '3-4-3' => { max_defenders: 4, max_midfielders: 4, max_attackers: 3 },
      '5-3-2' => { max_defenders: 5, max_midfielders: 3, max_attackers: 2 }
    }

    formation_limits.each do |formation, limits|
      # Act: Validar limites da formação
      post club_lineup_path(@club), params: {
        action: 'validate_formation_limits',
        formation: formation
      }, xhr: true

      # Assert: Limites corretos por setor
      assert_response :success
      response_data = JSON.parse(response.body)

      assert response_data['valid']
      assert_equal limits[:max_defenders], response_data['sector_limits']['defense']
      assert_equal limits[:max_midfielders], response_data['sector_limits']['midfield']
      assert_equal limits[:max_attackers], response_data['sector_limits']['attack']
    end
  end

  # TC004.7: Performance do algoritmo de fallback
  test "fallback algorithm performance" do
    # Arrange: Elenco complexo para testar performance
    create_complex_squad(@club, 30)

    # Act: Executar fallback com medição de tempo
    start_time = Time.current

    post club_lineup_path(@club), params: {
      action: 'find_best_formation',
      preferred_formation: '3-4-3'
    }, xhr: true

    end_time = Time.current
    execution_time = end_time - start_time

    # Assert: Execução rápida mesmo com elenco grande
    assert_response :success
    assert execution_time < 0.05, "Fallback levou #{execution_time}s (limite: 0.05s)"

    response_data = JSON.parse(response.body)
    assert response_data['success']
    assert response_data['execution_time'] < 50 # milissegundos
  end

  # TC004.8: Priorização tática
  test "tactical formation prioritization" do
    # Arrange: Elenco equilibrado que permite múltiplas formações
    create_versatile_squad(@club)

    tactical_preferences = [
      { style: 'offensive', expected: ['4-3-3', '3-4-3'] },
      { style: 'balanced', expected: ['4-4-2', '4-2-3-1'] },
      { style: 'defensive', expected: ['5-3-2', '4-5-1'] }
    ]

    tactical_preferences.each do |preference|
      # Act: Buscar formação por estilo tático
      post club_lineup_path(@club), params: {
        action: 'find_formation_by_style',
        tactical_style: preference[:style]
      }, xhr: true

      # Assert: Formação adequada ao estilo selecionada
      assert_response :success
      response_data = JSON.parse(response.body)

      assert response_data['success']
      assert_includes preference[:expected], response_data['selected_formation']
      assert_equal preference[:style], response_data['tactical_style']
    end
  end

  private

  def login_as(user)
    post session_path, params: { user_id: user.id }
  end

  def create_specific_squad(club, composition)
    club.players.destroy_all

    composition.each do |position, count|
      count.times do |i|
        Player.create!(
          club: club,
          name: "#{position} Player #{i + 1}",
          position: position,
          overall: 75 + rand(15)
        )
      end
    end
  end

  def create_limited_squad(club, composition)
    create_specific_squad(club, composition)
  end

  def create_balanced_433_squad(club)
    composition = {
      'GK' => 2, 'CB' => 4, 'LB' => 2, 'RB' => 2,
      'CDM' => 1, 'CM' => 4, 'CAM' => 2,
      'LW' => 2, 'RW' => 2, 'ST' => 3
    }
    create_specific_squad(club, composition)
  end

  def create_defensive_heavy_squad(club)
    composition = {
      'GK' => 2, 'CB' => 6, 'LB' => 2, 'RB' => 2,
      'CDM' => 4, 'CM' => 2, 'ST' => 2
    }
    create_specific_squad(club, composition)
  end

  def create_complex_squad(club, total_players)
    club.players.destroy_all

    positions = %w[GK CB LB RB CDM CM CAM LM RM LW RW ST]
    total_players.times do |i|
      position = positions[i % positions.length]
      Player.create!(
        club: club,
        name: "Complex Player #{i + 1}",
        position: position,
        overall: 60 + rand(30)
      )
    end
  end

  def create_versatile_squad(club)
    composition = {
      'GK' => 2, 'CB' => 4, 'LB' => 2, 'RB' => 2,
      'CDM' => 3, 'CM' => 4, 'CAM' => 2,
      'LM' => 2, 'RM' => 2, 'LW' => 2, 'RW' => 2, 'ST' => 3
    }
    create_specific_squad(club, composition)
  end
end