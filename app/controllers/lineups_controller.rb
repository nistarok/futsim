class LineupsController < ApplicationController
  before_action :set_lineup, only: [:show, :edit, :update, :destroy]
  before_action :set_club, only: [:index, :new, :create]

  def index
    @lineups = @club.lineups.includes(:players)
  end

  def show
    @starting_players = @lineup.lineup_players.joins(:player).where(starting: true).includes(:player)
    @substitute_players = @lineup.lineup_players.joins(:player).where(starting: false).includes(:player)
  end

  def new
    @lineup = @club.lineups.build
    @available_players = @club.players.includes(:position)
  end

  def create
    @lineup = @club.lineups.build(lineup_params)

    if @lineup.save
      redirect_to [@club, @lineup], notice: 'Escalação criada com sucesso!'
    else
      @available_players = @club.players.includes(:position)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_players = @lineup.club.players.includes(:position)
  end

  def update
    if @lineup.update(lineup_params)
      redirect_to [@lineup.club, @lineup], notice: 'Escalação atualizada com sucesso!'
    else
      @available_players = @lineup.club.players.includes(:position)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @club = @lineup.club
    @lineup.destroy
    redirect_to club_lineups_path(@club), notice: 'Escalação removida com sucesso!'
  end

  private

  def set_lineup
    @lineup = Lineup.find(params[:id])
  end

  def set_club
    @club = Club.find(params[:club_id])
  end

  def lineup_params
    params.require(:lineup).permit(:name, :formation, :active,
      lineup_players_attributes: [:id, :player_id, :position, :starting, :_destroy])
  end
end
