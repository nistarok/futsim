class ClubsController < ApplicationController
  before_action :authenticate_user!, except: [:rounds]
  before_action :set_club, only: [:show, :squad, :lineup, :create_lineup, :update_lineup, :rounds]
  before_action :set_available_club, only: [:update]
  before_action :set_test_user, only: [:rounds]

  def index
    @clubs = current_user.clubs.includes(:room, :division).order(:created_at)
  end

  def new
    @room = Room.find(params[:room_id]) if params[:room_id]

    if @room.nil?
      redirect_to rooms_path, alert: 'Sala não encontrada.'
      return
    end

    @club = @room.clubs.build
    @divisions = Division.all.order(:level)
  end

  def create
    @room = Room.find(params[:room_id]) if params[:room_id]

    if @room.nil?
      redirect_to rooms_path, alert: 'Sala não encontrada.'
      return
    end

    @club = @room.clubs.build(club_params)
    @club.user = current_user

    if @club.save
      redirect_to @club, notice: 'Clube criado com sucesso!'
    else
      @divisions = Division.all.order(:level)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @players = @club.players.includes(:club).order(:position, overall: :desc)
    @current_lineup = @club.lineups.where(active: true).first
  end

  def squad
    @players_by_position = {
      'GK' => @club.players.goalkeepers.order(overall: :desc),
      'Defense' => @club.players.defenders.order(overall: :desc),
      'Midfield' => @club.players.midfielders.order(overall: :desc),
      'Attack' => @club.players.forwards.order(overall: :desc)
    }
    @total_market_value = @club.players.sum(:market_value)
    @total_salary = @club.players.sum(:salary)
  end

  def lineup
    @current_lineup = @club.lineups.find_or_initialize_by(active: true) do |lineup|
      lineup.name = "Escalação Principal"
      lineup.formation = "4-4-2"
      lineup.match_date = Date.current
    end

    @players_by_position = {
      'GK' => @club.players.goalkeepers.order(overall: :desc),
      'CB' => @club.players.by_position('CB').order(overall: :desc),
      'LB' => @club.players.by_position('LB').order(overall: :desc),
      'RB' => @club.players.by_position('RB').order(overall: :desc),
      'CDM' => @club.players.by_position('CDM').order(overall: :desc),
      'CM' => @club.players.by_position('CM').order(overall: :desc),
      'CAM' => @club.players.by_position('CAM').order(overall: :desc),
      'LM' => @club.players.by_position('LM').order(overall: :desc),
      'RM' => @club.players.by_position('RM').order(overall: :desc),
      'LW' => @club.players.by_position('LW').order(overall: :desc),
      'RW' => @club.players.by_position('RW').order(overall: :desc),
      'ST' => @club.players.by_position('ST').order(overall: :desc)
    }

    @lineup_players = @current_lineup.persisted? ? @current_lineup.lineup_players.includes(:player) : []
  end

  def create_lineup
    @lineup = @club.lineups.build(lineup_params)
    @lineup.active = true
    @lineup.match_date = Date.current

    # Deactivate other lineups
    @club.lineups.where(active: true).update_all(active: false)

    if @lineup.save
      redirect_to lineup_club_path(@club), notice: t('notices.lineup_created')
    else
      redirect_to lineup_club_path(@club), alert: t('errors.lineup_creation_failed')
    end
  end

  def update
    if @club.available?
      @club.claim_by!(current_user)
      redirect_to @club, notice: "Você agora controla o #{@club.name}!"
    else
      redirect_to @club.room, alert: "Este clube não está mais disponível."
    end
  end

  def update_lineup
    # Find or create lineup
    @lineup = @club.lineups.find_or_create_by(active: true) do |lineup|
      lineup.name = "Escalação Principal"
      lineup.formation = "4-4-2"
      lineup.match_date = Date.current
    end

    # Clear existing lineup players
    @lineup.lineup_players.destroy_all

    # Add new players from params
    if params[:players].present?
      params[:players].each do |position_key, player_id|
        next if player_id.blank?

        # Extract position from key (format: "position_playerid")
        position = position_key.split('_').first

        @lineup.lineup_players.create!(
          player_id: player_id,
          position: position,
          starting: true
        )
      end
    end

    redirect_to lineup_club_path(@club), notice: t('notices.lineup_updated')
  rescue => e
    Rails.logger.error "Error updating lineup: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to lineup_club_path(@club), alert: t('errors.lineup_update_failed')
  end

  def rounds
    @room = @club.room
    @current_round = @room.current_round
    @rounds = @room.rounds.order(:number).limit(10)
    @user_approval_status = @current_round&.user_approval_status(current_user) || 'no_round'
  end

  private

  def set_club
    @club = current_user.clubs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('errors.club_not_found')
  end

  def set_available_club
    @club = Club.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('errors.club_not_found')
  end

  def club_params
    params.require(:club).permit(:name, :city, :founded_year, :stadium_name, :stadium_capacity, :budget, :division_id)
  end

  def lineup_params
    params.require(:lineup).permit(:name, :formation)
  end
end