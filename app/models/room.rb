class Room < ApplicationRecord
  belongs_to :user
  has_many :clubs, dependent: :destroy
  has_many :rounds, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :is_multiplayer, inclusion: { in: [true, false] }
  validates :max_players, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 16 }
  validates :current_players, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: ['waiting', 'active', 'finished'] }

  # Custom validation for max singleplayer rooms per user
  validate :limit_singleplayer_rooms_per_user, if: -> { is_multiplayer == false }

  # Scopes
  scope :singleplayer, -> { where(is_multiplayer: false) }
  scope :multiplayer, -> { where(is_multiplayer: true) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_status, ->(status) { where(status: status) }

  # Methods
  def multiplayer?
    is_multiplayer
  end

  def singleplayer?
    !is_multiplayer
  end

  def full?
    current_players >= max_players
  end

  def can_add_player?
    current_players < max_players
  end

  # Métodos para rodadas
  def current_round
    rounds.current.first
  end

  def latest_round
    rounds.order(:number).last
  end

  def create_next_round!
    next_number = latest_round&.number&.+(1) || 1

    rounds.create!(
      number: next_number,
      status: Round::PREPARATION,
      start_date: Date.current,
      end_date: Date.current + 7.days
    )
  end

  def active_users_count
    clubs.joins(:user).distinct.count(:user_id)
  end

  private

  def limit_singleplayer_rooms_per_user
    return unless user_id.present?

    singleplayer_count = Room.singleplayer.where(user: user).where.not(id: id).count
    if singleplayer_count >= 5
      errors.add(:base, 'Você pode ter no máximo 5 salas singleplayer')
    end
  end
end
