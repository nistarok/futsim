class MoveApproval < ApplicationRecord
  belongs_to :user
  belongs_to :round

  # Status possíveis
  PENDING = 'pending'.freeze
  APPROVED = 'approved'.freeze
  REJECTED = 'rejected'.freeze

  validates :status, presence: true, inclusion: { in: [PENDING, APPROVED, REJECTED] }
  validates :user_id, uniqueness: { scope: :round_id, message: "já aprovou esta rodada" }

  # Scopes
  scope :pending, -> { where(status: PENDING) }
  scope :approved, -> { where(status: APPROVED) }
  scope :rejected, -> { where(status: REJECTED) }
  scope :by_round, ->(round) { where(round: round) }
  scope :by_user, ->(user) { where(user: user) }

  # Métodos
  def pending?
    status == PENDING
  end

  def approved?
    status == APPROVED
  end

  def rejected?
    status == REJECTED
  end

  def approve!
    update!(status: APPROVED, approved_at: Time.current)
  end

  def reject!
    update!(status: REJECTED, approved_at: Time.current)
  end
end
