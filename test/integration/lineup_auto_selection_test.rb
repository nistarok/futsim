# Test: TEST-INT-002 - Seleção Automática Inteligente
# Objetivo: Validar algoritmo de seleção automática com todos os critérios

require 'test_helper'

class LineupAutoSelectionTest < ActionDispatch::IntegrationTest
  def setup
    @club = clubs(:fluminense)
    @user = users(:admin)
    login_as @user
  end

  # TC002.1: Seleção com elenco completo
  test "auto select with full squad" do
    # Arrange: Clube com 20+ jogadores em todas posições
    ensure_full_squad(@club)

    # Act: Executar seleção automática
    post club_lineup_path(@club), params: {
      action: 'auto_select',
      formation: '4-4-2'
    }, xhr: true

    # Assert: 11 jogadores selecionados, formação mantida
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 11, response_data['selected_count']
    assert_equal '4-4-2', response_data['formation_used']
    assert response_data['message'].include?('selecionados automaticamente')
  end

  # TC002.2: Seleção com elenco limitado
  test "auto select with limited squad" do
    # Arrange: Clube com poucos jogadores (13-15)
    limit_squad_size(@club, 15)

    # Act: Executar seleção automática
    post club_lineup_path(@club), params: {
      action: 'auto_select',
      formation: '4-3-3'
    }, xhr: true

    # Assert: 11 jogadores selecionados, posições adaptadas
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 11, response_data['selected_count']
    assert response_data['formation_adapted']
    assert response_data['adaptations'].any?
  end

  # TC002.3: Priorização por overall
  test "prioritizes higher overall players" do
    # Arrange: Múltiplos jogadores na mesma posição
    create_position_competition(@club, 'CB', [85, 82, 79, 76])

    # Act: Seleção automática
    post club_lineup_path(@club), params: {
      action: 'auto_select',
      formation: '5-3-2'
    }, xhr: true

    # Assert: Jogadores com maior overall selecionados primeiro
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    selected_cbs = response_data['selected_players_by_position']['CB']
    assert selected_cbs.length >= 2

    # Verificar que os CBs selecionados têm overall mais alto
    selected_overalls = selected_cbs.map { |cb| cb['adjusted_overall'] }
    assert selected_overalls.all? { |overall| overall >= 82 }
  end

  # TC002.4: Fallback de formação
  test "formation fallback when needed" do
    # Arrange: Elenco incompatível com formação selecionada
    create_unbalanced_squad(@club, { 'GK' => 2, 'CB' => 2, 'CM' => 8, 'ST' => 2 })

    # Act: Tentar seleção automática com 3-4-3 (precisa de 3 atacantes)
    post club_lineup_path(@club), params: {
      action: 'auto_select',
      formation: '3-4-3'
    }, xhr: true

    # Assert: Formação adaptada, mensagem exibida
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 11, response_data['selected_count']
    assert_not_equal '3-4-3', response_data['formation_used']
    assert response_data['formation_fallback_used']
    assert response_data['message'].include?('adaptada')
  end

  # TC002.5: Seleção com jogadores lesionados
  test "skips injured players" do
    # Arrange: Marcar alguns jogadores como lesionados
    injured_players = @club.players.limit(3)
    injured_players.update_all(injured: true)

    # Act: Seleção automática
    post club_lineup_path(@club), params: {
      action: 'auto_select',
      formation: '4-4-2'
    }, xhr: true

    # Assert: Jogadores lesionados não selecionados
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 11, response_data['selected_count']

    selected_ids = response_data['selected_players']
    injured_ids = injured_players.pluck(:id)
    assert (selected_ids & injured_ids).empty?
  end

  # TC002.6: Otimização por química
  test "optimizes selection by chemistry" do
    # Arrange: Jogadores com diferentes adequações por posição
    create_chemistry_test_players(@club)

    # Act: Seleção automática
    post club_lineup_path(@club), params: {
      action: 'auto_select',
      formation: '4-4-2'
    }, xhr: true

    # Assert: Priorização de jogadores com melhor química
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 11, response_data['selected_count']

    # Verificar que pelo menos alguns jogadores têm bônus de química
    chemistry_bonuses = response_data['selected_players_details'].map { |p| p['chemistry_bonus'] }
    assert chemistry_bonuses.any? { |bonus| bonus > 0 }
  end

  # TC002.7: Tempo de resposta
  test "completes selection within time limit" do
    # Arrange: Elenco grande para testar performance
    ensure_full_squad(@club, 30)

    # Act & Assert: Seleção automática rápida
    start_time = Time.current

    post club_lineup_path(@club), params: {
      action: 'auto_select',
      formation: '4-4-2'
    }, xhr: true

    end_time = Time.current
    execution_time = end_time - start_time

    assert_response :success
    assert execution_time < 0.1, "Seleção levou #{execution_time}s (limite: 0.1s)"

    response_data = JSON.parse(response.body)
    assert response_data['success']
    assert_equal 11, response_data['selected_count']
  end

  # TC002.8: Limpeza antes da seleção
  test "clears previous selection before auto select" do
    # Arrange: Selecionar alguns jogadores manualmente primeiro
    manual_players = @club.players.limit(3)
    manual_players.each do |player|
      post club_lineup_path(@club), params: {
        action: 'toggle_player',
        player_id: player.id
      }, xhr: true
    end

    # Act: Executar seleção automática
    post club_lineup_path(@club), params: {
      action: 'auto_select',
      formation: '4-4-2'
    }, xhr: true

    # Assert: Seleção anterior foi limpa, nova seleção tem exatamente 11
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 11, response_data['selected_count']
    assert response_data['selection_cleared']
  end

  private

  def login_as(user)
    post session_path, params: { user_id: user.id }
  end

  def ensure_full_squad(club, total_players = 25)
    current_count = club.players.count
    if current_count < total_players
      positions = %w[GK CB LB RB CDM CM CAM LM RM LW RW ST]
      needed = total_players - current_count

      needed.times do |i|
        position = positions[i % positions.length]
        Player.create!(
          club: club,
          name: "Test Player #{current_count + i + 1}",
          position: position,
          overall: 70 + rand(20)
        )
      end
    end
  end

  def limit_squad_size(club, max_size)
    excess_players = club.players.offset(max_size)
    excess_players.destroy_all
  end

  def create_position_competition(club, position, overalls)
    # Remove jogadores existentes da posição
    club.players.where(position: position).destroy_all

    # Criar jogadores com overalls específicos
    overalls.each_with_index do |overall, index|
      Player.create!(
        club: club,
        name: "#{position} Player #{index + 1}",
        position: position,
        overall: overall
      )
    end
  end

  def create_unbalanced_squad(club, position_counts)
    # Limpar elenco existente
    club.players.destroy_all

    # Criar jogadores conforme especificado
    position_counts.each do |position, count|
      count.times do |i|
        Player.create!(
          club: club,
          name: "#{position} #{i + 1}",
          position: position,
          overall: 75 + rand(15)
        )
      end
    end
  end

  def create_chemistry_test_players(club)
    # Criar jogadores com atributos específicos para teste de química
    positions_with_stats = {
      'GK' => { goalkeeping: 85, reflexes: 80 },
      'CB' => { defense: 85, strength: 80 },
      'CM' => { passing: 85, stamina: 80 },
      'ST' => { attack: 85, speed: 80 }
    }

    positions_with_stats.each do |position, stats|
      2.times do |i|
        player = Player.create!(
          club: club,
          name: "Chemistry #{position} #{i + 1}",
          position: position,
          overall: 75
        )

        # Definir atributos específicos para testar química
        stats.each do |stat_name, value|
          player.send("#{stat_name}=", value)
        end
        player.save!
      end
    end
  end
end