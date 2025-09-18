class PagesController < ApplicationController
  def home
    @current_user = User.find(session[:user_id]) if session[:user_id]

    if @current_user
      # Carregar dados reais do usuário
      @user_clubs = @current_user.clubs.includes(:room, :division, :players)
      @singleplayer_clubs = @user_clubs.singleplayer
      @multiplayer_rooms = @current_user.rooms.multiplayer.includes(:clubs)

      # Estatísticas gerais (calculadas dos dados reais)
      @total_matches = calculate_total_matches
      @total_wins = calculate_total_wins
      @win_rate = calculate_win_rate
      @total_budget = @user_clubs.sum(:budget)
    end
  end

  private

  def calculate_total_matches
    # Por enquanto retorna 0, mas pode ser implementado quando tivermos sistema de partidas
    0
  end

  def calculate_total_wins
    # Por enquanto retorna 0, mas pode ser implementado quando tivermos sistema de partidas
    0
  end

  def calculate_win_rate
    return 0 if calculate_total_matches == 0
    (calculate_total_wins.to_f / calculate_total_matches * 100).round(1)
  end
end
