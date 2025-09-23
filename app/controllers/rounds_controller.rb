class RoundsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room
  before_action :ensure_user_in_room
  before_action :set_round, only: [:show, :approve, :simulate, :simulation_results]

  def show
    # Buscar a rodada atual ou mais recente
    @current_round = @room.rounds.current.first || @room.rounds.order(created_at: :desc).first
    @matches = @current_round&.matches&.includes(:home_club, :away_club) || []
    @user_club = @room.clubs.find_by(user: current_user)
    @user_approval = @current_round&.move_approvals&.find_by(user: current_user)

    # Estatísticas da aprovação
    @total_users = @room.clubs.joins(:user).distinct.count(:user_id)
    @approved_users = @current_round&.move_approvals&.approved&.distinct&.count(:user_id) || 0
    @pending_users = @total_users - @approved_users

    # Lista de usuários e status
    @users_status = @room.clubs.joins(:user).includes(:user).map do |club|
      approval_status = @current_round&.user_approval_status(club.user) || 'not_submitted'
      {
        user: club.user,
        club: club,
        status: approval_status,
        approved?: approval_status == 'approved'
      }
    end
  end

  def create
    # Apenas o criador da sala pode criar rodadas
    unless @room.user == current_user
      redirect_to @room, alert: 'Apenas o criador da sala pode criar rodadas.'
      return
    end

    # Criar nova rodada para a sala
    @round = @room.rounds.build(
      number: next_round_number,
      status: Round::PREPARATION,
      start_date: Date.current,
      end_date: Date.current + 7.days
    )

    if @round.save
      # Gerar confrontos da rodada
      generate_matches_for_round(@round)
      redirect_to room_round_path(@room, @round), notice: t('rounds.created_successfully')
    else
      redirect_to @room, alert: t('rounds.creation_failed')
    end
  end

  def approve
    @approval = @round.move_approvals.find_or_initialize_by(user: current_user)

    if @approval.persisted? && @approval.approved?
      redirect_to room_round_path(@room, @round), notice: t('rounds.already_approved')
      return
    end

    @approval.assign_attributes(status: MoveApproval::APPROVED, approved_at: Time.current)

    if @approval.save
      # Verificar se todos aprovaram
      if @round.ready_for_simulation?
        @round.mark_as_approved!
        # TODO: Broadcast via ActionCable que rodada foi aprovada
      end

      redirect_to room_round_path(@room, @round), notice: t('rounds.approved_successfully')
    else
      redirect_to room_round_path(@room, @round), alert: t('rounds.approval_failed')
    end
  end

  def simulate
    unless @round.approved?
      redirect_to room_round_path(@room, @round), alert: t('rounds.not_ready_for_simulation')
      return
    end

    # Apenas o criador da sala pode executar a simulação
    unless @room.user == current_user
      redirect_to room_round_path(@room, @round), alert: 'Apenas o criador da sala pode executar a simulação.'
      return
    end

    @round.start_simulation!

    # Simular todas as partidas da rodada
    simulation_results = []

    @round.matches.scheduled.each do |match|
      if match.simulate!
        match.reload # Recarregar o match com os dados atualizados do banco
        simulation_results << {
          match: match,
          result: "#{match.home_club.name} #{match.home_score} x #{match.away_score} #{match.away_club.name}",
          events: match.events
        }
      end
    end

    @round.complete_simulation!

    # TODO: Broadcast resultados via ActionCable
    # TODO: Atualizar tabela de classificação

    # Salvar resultados na sessão para mostrar na próxima página
    session[:simulation_results] = simulation_results
    redirect_to simulation_results_room_round_path(@room, @round), notice: t('rounds.simulation_completed')
  end

  def simulation_results
    # Tentar pegar dados da sessão primeiro
    @simulation_results = session[:simulation_results]

    # Se não houver dados na sessão, reconstruir dos matches completados
    if @simulation_results.blank?
      @simulation_results = []
      @round.matches.completed.includes(:home_club, :away_club).each do |match|
        @simulation_results << {
          match: match,
          result: "#{match.home_club.name} #{match.home_score} x #{match.away_score} #{match.away_club.name}",
          events: match.events
        }
      end
    end

    session[:simulation_results] = nil # Limpar da sessão após usar
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def ensure_user_in_room
    unless @room.clubs.exists?(user: current_user)
      redirect_to @room, alert: t('rooms.access_denied')
    end
  end

  def set_round
    @round = @room.rounds.find(params[:id])
  end

  def next_round_number
    (@room.rounds.maximum(:number) || 0) + 1
  end

  def generate_matches_for_round(round)
    # Pegar todos os clubes da sala
    clubs = @room.clubs.includes(:user).to_a
    return if clubs.size < 2

    # Algoritmo simples de geração de confrontos (round-robin)
    # Para primeira implementação, vamos fazer confrontos aleatórios
    clubs.shuffle!

    # Criar confrontos (cada clube joga contra outro)
    (clubs.size / 2).times do |i|
      home_club = clubs[i * 2]
      away_club = clubs[i * 2 + 1]

      round.matches.create!(
        home_club: home_club,
        away_club: away_club,
        match_date: round.start_date + rand(0..6).days,
        status: Match::SCHEDULED
      )
    end
  end
end