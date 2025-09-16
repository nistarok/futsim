class RoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room, only: [:show, :edit, :update, :destroy]

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

  private

  def set_room
    @room = current_user.rooms.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:name, :description, :is_multiplayer, :max_players)
  end
end
