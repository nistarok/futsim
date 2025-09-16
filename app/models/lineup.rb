class Lineup < ApplicationRecord
  belongs_to :club
  has_many :lineup_players, dependent: :destroy
  has_many :players, through: :lineup_players
  accepts_nested_attributes_for :lineup_players, allow_destroy: true

  # Validations
  validates :name, presence: true
  validates :formation, presence: true, inclusion: {
    in: %w[4-4-2 4-3-3 3-5-2 4-5-1 3-4-3 5-3-2 4-2-3-1],
    message: 'deve ser uma formação válida'
  }
  validates :match_date, presence: true
  validates :active, inclusion: { in: [true, false] }

  # Custom validation
  validate :lineup_must_have_11_starting_players
  validate :lineup_must_have_one_goalkeeper

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_formation, ->(formation) { where(formation: formation) }
  scope :recent, -> { order(match_date: :desc) }

  # Methods
  def starting_players
    lineup_players.where(starting: true).includes(:player)
  end

  def substitute_players
    lineup_players.where(starting: false).includes(:player)
  end

  def goalkeeper
    starting_players.joins(:player).where(players: { position: 'GK' }).first&.player
  end

  def formation_positions
    case formation
    when '4-4-2'
      ['GK', 'LB', 'CB', 'CB', 'RB', 'LM', 'CM', 'CM', 'RM', 'ST', 'ST']
    when '4-3-3'
      ['GK', 'LB', 'CB', 'CB', 'RB', 'CDM', 'CM', 'CAM', 'LW', 'ST', 'RW']
    when '3-5-2'
      ['GK', 'CB', 'CB', 'CB', 'LM', 'CDM', 'CM', 'CAM', 'RM', 'ST', 'ST']
    when '4-5-1'
      ['GK', 'LB', 'CB', 'CB', 'RB', 'LM', 'CDM', 'CM', 'CAM', 'RM', 'ST']
    when '3-4-3'
      ['GK', 'CB', 'CB', 'CB', 'LM', 'CM', 'CM', 'RM', 'LW', 'ST', 'RW']
    when '5-3-2'
      ['GK', 'LB', 'CB', 'CB', 'CB', 'RB', 'CDM', 'CM', 'CAM', 'ST', 'ST']
    when '4-2-3-1'
      ['GK', 'LB', 'CB', 'CB', 'RB', 'CDM', 'CDM', 'CAM', 'CAM', 'CAM', 'ST']
    else
      []
    end
  end

  def team_strength
    starting_players.includes(:player).average('players.overall')&.round(1) || 0
  end

  private

  def lineup_must_have_11_starting_players
    return unless lineup_players.loaded? || persisted?

    starting_count = lineup_players.select(&:starting).count
    if starting_count != 11
      errors.add(:base, "Escalação deve ter exatamente 11 jogadores titulares (atual: #{starting_count})")
    end
  end

  def lineup_must_have_one_goalkeeper
    return unless lineup_players.loaded? || persisted?

    goalkeeper_count = lineup_players.select(&:starting).count do |lp|
      lp.player&.position == 'GK'
    end

    if goalkeeper_count != 1
      errors.add(:base, 'Escalação deve ter exatamente 1 goleiro titular')
    end
  end
end
