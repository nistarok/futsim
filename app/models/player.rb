class Player < ApplicationRecord
  belongs_to :club

  # Validations
  validates :name, presence: true
  validates :position, presence: true, inclusion: {
    in: ['GK', 'CB', 'LB', 'RB', 'CDM', 'CM', 'CAM', 'LM', 'RM', 'LW', 'RW', 'ST'],
    message: 'deve ser uma posição válida'
  }
  validates :overall, presence: true, numericality: {
    greater_than_or_equal_to: 30,
    less_than_or_equal_to: 99
  }
  validates :age, presence: true, numericality: {
    greater_than_or_equal_to: 16,
    less_than_or_equal_to: 45
  }
  validates :market_value, presence: true, numericality: { greater_than: 0 }
  validates :salary, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :by_position, ->(position) { where(position: position) }
  scope :by_club, ->(club) { where(club: club) }
  scope :goalkeepers, -> { where(position: 'GK') }
  scope :defenders, -> { where(position: ['CB', 'LB', 'RB']) }
  scope :midfielders, -> { where(position: ['CDM', 'CM', 'CAM', 'LM', 'RM']) }
  scope :forwards, -> { where(position: ['LW', 'RW', 'ST']) }
  scope :best_overall, -> { order(overall: :desc) }

  # Methods
  def position_name
    case position
    when 'GK' then 'Goleiro'
    when 'CB' then 'Zagueiro Central'
    when 'LB' then 'Lateral Esquerdo'
    when 'RB' then 'Lateral Direito'
    when 'CDM' then 'Volante'
    when 'CM' then 'Meio-Campo'
    when 'CAM' then 'Meia Ofensivo'
    when 'LM' then 'Meia Esquerda'
    when 'RM' then 'Meia Direita'
    when 'LW' then 'Ponta Esquerda'
    when 'RW' then 'Ponta Direita'
    when 'ST' then 'Atacante'
    else position
    end
  end

  def market_value_formatted
    "R$ #{ActionController::Base.helpers.number_with_delimiter(market_value)}"
  end

  def salary_formatted
    "R$ #{ActionController::Base.helpers.number_with_delimiter(salary)}"
  end

  def young_talent?
    age <= 21 && overall >= 70
  end

  def veteran?
    age >= 35
  end

  def starter_quality?
    overall >= 75
  end
end
