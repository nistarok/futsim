class Round < ApplicationRecord
  belongs_to :room
  has_many :move_approvals, dependent: :destroy
  has_many :matches, dependent: :destroy

  # Status possíveis
  PREPARATION = 'preparation'.freeze  # Usuários fazendo escalações
  APPROVED = 'approved'.freeze        # Todos aprovaram, pronto para simular
  SIMULATING = 'simulating'.freeze    # Rodada sendo simulada
  COMPLETED = 'completed'.freeze      # Rodada finalizada

  # Status de simulação
  SIM_PENDING = 'pending'.freeze              # Aguardando início
  SIM_RUNNING = 'running'.freeze              # Simulando
  SIM_HALFTIME_BREAK = 'halftime_break'.freeze # Pausa intervalo
  SIM_PAUSED_RED_CARD = 'paused_red_card'.freeze # Pausa expulsão
  SIM_PAUSED_INJURY = 'paused_injury'.freeze     # Pausa lesão
  SIM_PAUSED_PENALTY = 'paused_penalty'.freeze   # Pausa pênalti
  SIM_COMPLETED = 'completed'.freeze             # Simulação concluída
  SIM_FAILED = 'failed'.freeze                   # Simulação falhou

  validates :number, presence: true, uniqueness: { scope: :room_id }
  validates :status, presence: true, inclusion: { in: [PREPARATION, APPROVED, SIMULATING, COMPLETED] }
  validates :simulation_status, inclusion: {
    in: [SIM_PENDING, SIM_RUNNING, SIM_HALFTIME_BREAK, SIM_PAUSED_RED_CARD,
         SIM_PAUSED_INJURY, SIM_PAUSED_PENALTY, SIM_COMPLETED, SIM_FAILED],
    allow_nil: true
  }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :current_minute, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 90,
    allow_nil: true
  }

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :current, -> { where(status: [PREPARATION, APPROVED]) }
  scope :completed, -> { where(status: COMPLETED) }
  scope :by_room, ->(room) { where(room: room) }

  # Métodos de status
  def preparation?
    status == PREPARATION
  end

  def approved?
    status == APPROVED
  end

  def simulating?
    status == SIMULATING
  end

  def completed?
    status == COMPLETED
  end

  # Métodos de status de simulação
  def simulation_pending?
    simulation_status == SIM_PENDING || simulation_status.nil?
  end

  def simulation_running?
    simulation_status == SIM_RUNNING
  end

  def simulation_paused?
    [SIM_HALFTIME_BREAK, SIM_PAUSED_RED_CARD, SIM_PAUSED_INJURY, SIM_PAUSED_PENALTY].include?(simulation_status)
  end

  def simulation_completed?
    simulation_status == SIM_COMPLETED
  end

  def simulation_failed?
    simulation_status == SIM_FAILED
  end

  def simulation_in_progress?
    [SIM_RUNNING, SIM_HALFTIME_BREAK, SIM_PAUSED_RED_CARD, SIM_PAUSED_INJURY, SIM_PAUSED_PENALTY].include?(simulation_status)
  end

  # Helper para obter status traduzido
  def simulation_status_text
    return I18n.t('simulation.status.pending') if simulation_pending?
    I18n.t("simulation.status.#{simulation_status}")
  end

  # Lógica de aprovações
  def all_approved?
    active_users_count = room.clubs.joins(:user).distinct.count(:user_id)
    approved_count = move_approvals.approved.distinct.count(:user_id)

    active_users_count > 0 && approved_count >= active_users_count
  end

  def pending_approvals_count
    active_users_count = room.clubs.joins(:user).distinct.count(:user_id)
    approved_count = move_approvals.approved.distinct.count(:user_id)
    [active_users_count - approved_count, 0].max
  end

  def ready_for_simulation?
    preparation? && all_approved?
  end

  def user_approved?(user)
    move_approvals.approved.exists?(user: user)
  end

  def user_approval_status(user)
    approval = move_approvals.find_by(user: user)
    approval&.status || 'not_submitted'
  end

  # Transições de estado
  def mark_as_approved!
    return false unless ready_for_simulation?
    update!(status: APPROVED)
  end

  def start_simulation!
    return false unless approved?

    # Usar advisory lock para evitar race conditions
    with_advisory_lock("round_simulation_#{id}", timeout_seconds: 0) do
      reload # Recarregar dados mais recentes
      return false unless approved? && !simulation_in_progress?

      update!(
        status: SIMULATING,
        simulation_status: SIM_RUNNING,
        simulation_started_at: Time.current,
        current_minute: 0
      )
    end
  rescue ActiveRecord::AdvisoryLockTimeout
    Rails.logger.warn "Failed to acquire simulation lock for round #{id}"
    false
  end

  def complete_simulation!
    return false unless simulating?

    update!(
      status: COMPLETED,
      simulation_status: SIM_COMPLETED,
      simulation_completed_at: Time.current,
      end_date: Date.current,
      current_minute: 90
    )
  end

  def fail_simulation!(error_message = nil)
    update!(
      simulation_status: SIM_FAILED,
      simulation_completed_at: Time.current
    )

    Rails.logger.error "Round #{id} simulation failed: #{error_message}"

    # Reagendar simulação após 5 minutos
    RoundSimulationJob.set(wait: 5.minutes).perform_later(id)
  end

  def pause_simulation_for_human_decision!(pause_type, context = {})
    return false unless simulation_running?

    pause_status = case pause_type
    when :halftime then SIM_HALFTIME_BREAK
    when :red_card then SIM_PAUSED_RED_CARD
    when :injury then SIM_PAUSED_INJURY
    when :penalty then SIM_PAUSED_PENALTY
    else raise ArgumentError, "Invalid pause type: #{pause_type}"
    end

    update!(simulation_status: pause_status)

    # Broadcast para interface
    ActionCable.server.broadcast(
      "room_#{room_id}",
      {
        type: 'simulation_paused',
        round_id: id,
        pause_type: pause_type,
        message: I18n.t("simulation.decisions.#{pause_type}_changes"),
        context: context
      }
    )
  end

  def resume_simulation!
    return false unless simulation_paused?

    update!(simulation_status: SIM_RUNNING)

    # Reagendar job para continuar
    RoundSimulationJob.perform_later(id)
  end

  # Nome amigável da rodada
  def display_name
    "Rodada #{number}"
  end
end
