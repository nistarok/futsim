class LineupPlayer < ApplicationRecord
  belongs_to :lineup
  belongs_to :player

  # Validations
  validates :position, presence: true, inclusion: {
    in: ['GK', 'CB', 'LB', 'RB', 'CDM', 'CM', 'CAM', 'LM', 'RM', 'LW', 'RW', 'ST'],
    message: 'deve ser uma posição válida'
  }
  validates :starting, inclusion: { in: [true, false] }
  validates :substitution_minute, numericality: {
    greater_than: 0,
    less_than_or_equal_to: 120,
    allow_nil: true
  }

  # Ensure player can only appear once per lineup
  validates :player_id, uniqueness: {
    scope: :lineup_id,
    message: 'já está escalado nesta formação'
  }

  # Custom validation
  validate :position_compatible_with_player
  validate :substitution_minute_only_for_non_starting

  # Scopes
  scope :starting, -> { where(starting: true) }
  scope :substitutes, -> { where(starting: false) }
  scope :by_position, ->(position) { where(position: position) }

  # Methods
  def starter?
    starting
  end

  def substitute?
    !starting
  end

  def was_substituted?
    substitution_minute.present?
  end

  def position_name
    case position
    when 'GK' then 'Goleiro'
    when 'CB' then 'Zagueiro'
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

  private

  def position_compatible_with_player
    return unless player&.position && position

    # Goalkeeper must be in GK position
    if player.position == 'GK' && position != 'GK'
      errors.add(:position, 'Goleiro deve jogar na posição GK')
    elsif player.position != 'GK' && position == 'GK'
      errors.add(:position, 'Apenas goleiros podem jogar na posição GK')
    end
  end

  def substitution_minute_only_for_non_starting
    if starting && substitution_minute.present?
      errors.add(:substitution_minute, 'não pode ser definido para jogadores titulares')
    end
  end
end
