# Test: TEST-INT-001 - Seleção Manual de Jogadores
# Objetivo: Validar seleção/deseleção manual com todas as regras de negócio

require 'test_helper'

class LineupManualSelectionTest < ActionDispatch::IntegrationTest
  def setup
    @club = clubs(:fluminense)
    @user = users(:admin)
    login_as @user
  end

  # TC001.1: Seleção básica de jogador
  test "can select single player" do
    post club_lineup_path(@club), params: {
      action: 'toggle_player',
      player_id: @club.players.first.id
    }, xhr: true

    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 1, response_data['selected_count']
    assert_includes response_data['selected_players'], @club.players.first.id
  end

  # TC001.2: Limite de 11 jogadores
  test "cannot exceed eleven players" do
    # Arrange: Selecionar 11 jogadores
    players = @club.players.limit(11)
    players.each do |player|
      post club_lineup_path(@club), params: {
        action: 'toggle_player',
        player_id: player.id
      }, xhr: true
    end

    # Act: Tentar selecionar 12º jogador
    twelfth_player = @club.players.where.not(id: players.ids).first
    post club_lineup_path(@club), params: {
      action: 'toggle_player',
      player_id: twelfth_player.id
    }, xhr: true

    # Assert: Erro retornado, contador permanece 11/11
    assert_response :success
    response_data = JSON.parse(response.body)

    assert_not response_data['success']
    assert_equal 11, response_data['selected_count']
    assert_equal "Máximo de 11 jogadores permitido", response_data['message']
    assert_not_includes response_data['selected_players'], twelfth_player.id
  end

  # TC001.3: Deseleção de jogador
  test "can deselect player" do
    player = @club.players.first

    # Arrange: Selecionar jogador primeiro
    post club_lineup_path(@club), params: {
      action: 'toggle_player',
      player_id: player.id
    }, xhr: true

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data['success']
    assert_equal 1, response_data['selected_count']

    # Act: Clicar novamente no jogador (desselecionar)
    post club_lineup_path(@club), params: {
      action: 'toggle_player',
      player_id: player.id
    }, xhr: true

    # Assert: Jogador desmarcado, contador decrementado
    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert_equal 0, response_data['selected_count']
    assert_not_includes response_data['selected_players'], player.id
  end

  # TC001.4: Estado persistente
  test "selection persists across requests" do
    players = @club.players.limit(3)

    # Arrange: Selecionar alguns jogadores
    players.each do |player|
      post club_lineup_path(@club), params: {
        action: 'toggle_player',
        player_id: player.id
      }, xhr: true
    end

    # Act: Navegar para página de escalação novamente
    get club_lineup_path(@club)

    # Assert: Seleção mantida, contador correto
    assert_response :success
    assert_select '[data-controller="lineup"]'

    # Verificar se estado foi preservado (via JavaScript no carregamento)
    assert_match /selectedPlayers.*#{players.first.id}/, response.body
  end

  # TC001.5: Feedback visual imediato
  test "provides immediate visual feedback" do
    player = @club.players.first

    post club_lineup_path(@club), params: {
      action: 'toggle_player',
      player_id: player.id
    }, xhr: true

    assert_response :success
    response_data = JSON.parse(response.body)

    assert response_data['success']
    assert response_data['visual_update']
    assert_equal 'selected', response_data['player_state']
    assert_includes response_data['css_classes'], 'bg-green-50'
  end

  # TC001.6: Validação de jogador inexistente
  test "rejects invalid player selection" do
    post club_lineup_path(@club), params: {
      action: 'toggle_player',
      player_id: 99999 # ID inexistente
    }, xhr: true

    assert_response :success
    response_data = JSON.parse(response.body)

    assert_not response_data['success']
    assert_equal "Jogador não encontrado", response_data['message']
    assert_equal 0, response_data['selected_count']
  end

  # TC001.7: Validação de permissão de clube
  test "rejects selection from wrong club" do
    other_club = clubs(:santos)
    other_player = other_club.players.first

    post club_lineup_path(@club), params: {
      action: 'toggle_player',
      player_id: other_player.id
    }, xhr: true

    assert_response :success
    response_data = JSON.parse(response.body)

    assert_not response_data['success']
    assert_equal "Jogador não pertence ao clube", response_data['message']
    assert_equal 0, response_data['selected_count']
  end

  # TC001.8: Contador de jogadores selecionados
  test "maintains accurate player count" do
    players = @club.players.limit(5)

    players.each_with_index do |player, index|
      post club_lineup_path(@club), params: {
        action: 'toggle_player',
        player_id: player.id
      }, xhr: true

      assert_response :success
      response_data = JSON.parse(response.body)

      assert response_data['success']
      assert_equal index + 1, response_data['selected_count']
      assert_equal "#{index + 1}/11", response_data['count_display']
    end
  end

  private

  def login_as(user)
    post session_path, params: { user_id: user.id }
  end
end