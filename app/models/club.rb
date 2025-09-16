class Club < ApplicationRecord
  # Associations
  belongs_to :division
  belongs_to :user
  belongs_to :room  # Sempre pertence a uma sala (single ou multiplayer)
  has_many :players, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :city, presence: true
  validates :founded_year, presence: true, numericality: {
    greater_than: 1800,
    less_than_or_equal_to: Date.current.year
  }
  validates :stadium_name, presence: true
  validates :stadium_capacity, presence: true, numericality: { greater_than: 0 }
  validates :budget, presence: true, numericality: { greater_than: 0 }

  # Nome do clube deve ser único por sala
  validates :name, uniqueness: { scope: :room_id, message: "já existe nesta sala" }

  # Scopes
  scope :by_division, ->(division) { where(division: division) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_room, ->(room) { where(room: room) }
  scope :singleplayer, -> { joins(:room).where(rooms: { is_multiplayer: false }) }
  scope :multiplayer, -> { joins(:room).where(rooms: { is_multiplayer: true }) }

  # Methods
  def full_name
    "#{name} - #{city}"
  end

  def squad_size
    players.count
  end

  def average_overall
    return 0 if players.empty?
    players.average(:overall).round(1)
  end

  def budget_formatted
    "R$ #{budget.to_s(:delimited)}"
  end

  def team_strength
    return 0 if players.empty?
    best_players = players.order(overall: :desc).limit(11)
    return 0 if best_players.empty?
    best_players.average(:overall).round(1)
  end

  def initials
    name.split.map(&:first).join.upcase[0..2]
  end

  def multiplayer?
    room_id.present?
  end

  def singleplayer?
    room_id.nil?
  end
end
