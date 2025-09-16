class Division < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :level, presence: true, uniqueness: true, inclusion: { in: 1..5 }
  validates :description, presence: true

  # Associations
  has_many :clubs, dependent: :destroy
  has_many :seasons, dependent: :destroy

  # Scopes
  scope :ordered_by_level, -> { order(:level) }

  # Methods
  def display_name
    "#{level}ª Divisão - #{name}"
  end

  def self.seed_default_divisions
    divisions = [
      { name: "Primeira Divisão", level: 1, description: "Elite do futebol brasileiro" },
      { name: "Segunda Divisão", level: 2, description: "Série B do campeonato" },
      { name: "Terceira Divisão", level: 3, description: "Série C do campeonato" },
      { name: "Quarta Divisão", level: 4, description: "Série D do campeonato" },
      { name: "Quinta Divisão", level: 5, description: "Divisão de acesso" }
    ]

    divisions.each do |div|
      Division.find_or_create_by(level: div[:level]) do |division|
        division.name = div[:name]
        division.description = div[:description]
      end
    end
  end
end
