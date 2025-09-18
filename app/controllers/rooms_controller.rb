class RoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room, only: [:show, :edit, :update, :destroy, :choose_random_club, :start_game]

  def index
    @singleplayer_rooms = current_user.rooms.singleplayer.includes(:clubs)
    @multiplayer_rooms = current_user.rooms.multiplayer.includes(:clubs)
    @available_multiplayer_rooms = Room.multiplayer.where.not(user: current_user).where(status: 'waiting')
  end

  def show
    @clubs = @room.clubs.includes(:players)
    @members = User.joins(:rooms).where(rooms: { id: @room.id })
  end

  def new
    @room = current_user.rooms.build

    # Set defaults based on type parameter
    if params[:type] == 'single'
      @room.is_multiplayer = false
      @room.max_players = 1
    else
      @room.is_multiplayer = true
      @room.max_players = 16
    end

    # Set required defaults
    @room.current_players = 1
    @room.status = 'waiting'
  end

  def create
    @room = current_user.rooms.build(room_params)

    # Set required defaults if not set
    @room.current_players ||= 1
    @room.status ||= 'waiting'

    if @room.save
      # Gerar clubes padrão com jogadores
      PlayerPoolGeneratorService.new(@room).generate_default_clubs!
      redirect_to @room, notice: t('notices.room_created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @room.update(room_params)
      redirect_to @room, notice: t('notices.room_updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @room.destroy
    redirect_to rooms_path, notice: t('notices.room_deleted')
  end

  def choose_random_club
    random_club = @room.clubs.available.order('RANDOM()').first

    if random_club.nil?
      redirect_to @room, alert: t('alerts.no_clubs_available')
      return
    end

    random_club.claim_by!(current_user)
    redirect_to club_path(random_club), notice: t('notices.club_chosen_randomly', club_name: random_club.name)
  end

  def start_game
    # Verificar se o usuário tem um clube na sala
    user_club = @room.clubs.where(user: current_user).first

    if user_club.nil?
      redirect_to @room, alert: t('alerts.need_to_choose_club')
      return
    end

    # Verificar se o clube tem escalação ativa
    if user_club.lineups.where(active: true).empty?
      redirect_to lineup_club_path(user_club), alert: t('alerts.need_to_create_lineup')
      return
    end

    # Atualizar status da sala para ativa
    @room.update!(status: 'active')

    # Criar primeira rodada se não existir
    if @room.rounds.empty?
      @room.create_next_round!
    end

    redirect_to club_path(user_club), notice: t('notices.game_started')
  end

  private

  def set_room
    @room = current_user.rooms.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:name, :description, :is_multiplayer, :max_players)
  end
end
