class Round < ApplicationRecord
  belongs_to :room
  has_many :move_approvals, dependent: :destroy
  has_many :matches, dependent: :destroy

  # Status possíveis
  PREPARATION = 'preparation'.freeze  # Usuários fazendo escalações
  APPROVED = 'approved'.freeze        # Todos aprovaram, pronto para simular
  SIMULATING = 'simulating'.freeze    # Rodada sendo simulada
  COMPLETED = 'completed'.freeze      # Rodada finalizada

  validates :number, presence: true, uniqueness: { scope: :room_id }
  validates :status, presence: true, inclusion: { in: [PREPARATION, APPROVED, SIMULATING, COMPLETED] }
  validates :start_date, presence: true
  validates :end_date, presence: true

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
    update!(status: SIMULATING)
  end

  def complete_simulation!
    return false unless simulating?
    update!(status: COMPLETED, end_date: Date.current)
  end

  # Nome amigável da rodada
  def display_name
    "Rodada #{number}"
  end
end
