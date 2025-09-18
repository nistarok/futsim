class Match < ApplicationRecord
  belongs_to :round
  belongs_to :home_club, class_name: 'Club'
  belongs_to :away_club, class_name: 'Club'

  # Status possíveis
  SCHEDULED = 'scheduled'.freeze
  SIMULATING = 'simulating'.freeze
  COMPLETED = 'completed'.freeze

  validates :status, presence: true, inclusion: { in: [SCHEDULED, SIMULATING, COMPLETED] }
  validates :match_date, presence: true
  validate :different_clubs
  validate :scores_valid_when_completed

  # Scopes
  scope :by_round, ->(round) { where(round: round) }
  scope :by_club, ->(club) { where('home_club_id = ? OR away_club_id = ?', club.id, club.id) }
  scope :scheduled, -> { where(status: SCHEDULED) }
  scope :completed, -> { where(status: COMPLETED) }

  # Métodos de status
  def scheduled?
    status == SCHEDULED
  end

  def simulating?
    status == SIMULATING
  end

  def completed?
    status == COMPLETED
  end

  # Resultados
  def home_win?
    completed? && home_score > away_score
  end

  def away_win?
    completed? && away_score > home_score
  end

  def draw?
    completed? && home_score == away_score
  end

  def winner
    return nil unless completed?
    return home_club if home_win?
    return away_club if away_win?
    nil # empate
  end

  def loser
    return nil unless completed?
    return away_club if home_win?
    return home_club if away_win?
    nil # empate
  end

  # Pontos por resultado
  def points_for_club(club)
    return 0 unless completed?

    if club == home_club
      return 3 if home_win?
      return 1 if draw?
      return 0
    elsif club == away_club
      return 3 if away_win?
      return 1 if draw?
      return 0
    else
      0
    end
  end

  def score_for_club(club)
    return home_score if club == home_club
    return away_score if club == away_club
    0
  end

  def score_against_club(club)
    return away_score if club == home_club
    return home_score if club == away_club
    0
  end

  def display_result
    return "#{home_club.name} vs #{away_club.name}" unless completed?
    "#{home_club.name} #{home_score} x #{away_score} #{away_club.name}"
  end

  # Simular partida
  def simulate!
    return false unless scheduled?

    MatchSimulatorService.new(self).simulate!
  end

  # Métodos para acessar eventos da partida
  def events
    return [] if match_events.blank?

    JSON.parse(match_events).map(&:with_indifferent_access)
  rescue JSON::ParserError
    []
  end

  def goals_events
    events.select { |event| event[:type] == 'goal' }
  end

  def chances_events
    events.select { |event| event[:type] == 'chance' }
  end

  private

  def different_clubs
    return unless home_club_id && away_club_id
    errors.add(:away_club, 'não pode ser o mesmo que o clube mandante') if home_club_id == away_club_id
  end

  def scores_valid_when_completed
    return unless completed?
    errors.add(:home_score, 'deve estar presente quando partida finalizada') if home_score.nil?
    errors.add(:away_score, 'deve estar presente quando partida finalizada') if away_score.nil?
    errors.add(:home_score, 'deve ser maior ou igual a zero') if home_score&.< 0
    errors.add(:away_score, 'deve ser maior ou igual a zero') if away_score&.< 0
  end

end
