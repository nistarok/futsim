class Room < ApplicationRecord
  belongs_to :user
  has_many :clubs, dependent: :destroy

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

  private

  def limit_singleplayer_rooms_per_user
    return unless user_id.present?

    singleplayer_count = Room.singleplayer.where(user: user).where.not(id: id).count
    if singleplayer_count >= 5
      errors.add(:base, 'Você pode ter no máximo 5 salas singleplayer')
    end
  end
end
