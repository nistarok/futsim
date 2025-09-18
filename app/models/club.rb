class Club < ApplicationRecord
  # Associations
  belongs_to :division
  belongs_to :user, optional: true  # Permite clubes NPCs (sem usuário)
  belongs_to :room  # Sempre pertence a uma sala (single ou multiplayer)
  has_many :players, dependent: :destroy
  has_many :lineups, dependent: :destroy

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
  validates :available, inclusion: { in: [true, false] }

  # Nome do clube deve ser único por sala
  validates :name, uniqueness: { scope: :room_id, message: "já existe nesta sala" }

  # Scopes
  scope :by_division, ->(division) { where(division: division) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_room, ->(room) { where(room: room) }
  scope :available, -> { where(available: true) }
  scope :taken, -> { where(available: false) }
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
    "R$ #{ActionController::Base.helpers.number_with_delimiter(budget)}"
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

  def controlled_by_user?
    user_id.present?
  end

  def npc?
    user_id.nil?
  end

  def available?
    available == true
  end

  def taken?
    !available?
  end

  def claim_by!(user)
    update!(user: user, available: false)
  end

  def team_colors
    CLUB_COLORS[name] || CLUB_COLORS['default']
  end

  def primary_color
    team_colors[:primary]
  end

  def secondary_color
    team_colors[:secondary]
  end

  def gradient
    "linear-gradient(to right, #{primary_color}, #{secondary_color})"
  end

  private

  CLUB_COLORS = {
    # Clubes Brasileiros com cores reais
    'Flamengo' => {
      primary: '#E30613',    # Vermelho
      secondary: '#000000',   # Preto
      accent: '#FFFFFF'       # Branco
    },
    'Palmeiras' => {
      primary: '#00A859',     # Verde
      secondary: '#FFFFFF',   # Branco
      accent: '#000000'       # Preto
    },
    'Santos' => {
      primary: '#000000',     # Preto
      secondary: '#FFFFFF',   # Branco
      accent: '#C4C4C4'       # Cinza claro
    },
    'Corinthians' => {
      primary: '#000000',     # Preto
      secondary: '#FFFFFF',   # Branco
      accent: '#C4C4C4'       # Cinza claro
    },
    'São Paulo' => {
      primary: '#FF0000',     # Vermelho
      secondary: '#000000',   # Preto
      accent: '#FFFFFF'       # Branco
    },
    'Grêmio' => {
      primary: '#0080C7',     # Azul
      secondary: '#000000',   # Preto
      accent: '#FFFFFF'       # Branco
    },
    'Internacional' => {
      primary: '#FF0000',     # Vermelho
      secondary: '#FFFFFF',   # Branco
      accent: '#000000'       # Preto
    },
    'Vasco da Gama' => {
      primary: '#000000',     # Preto
      secondary: '#FFFFFF',   # Branco
      accent: '#C4C4C4'       # Cinza claro
    },
    'Botafogo' => {
      primary: '#000000',     # Preto
      secondary: '#FFFFFF',   # Branco
      accent: '#C4C4C4'       # Cinza claro
    },
    'Fluminense' => {
      primary: '#8B0000',     # Grená
      secondary: '#00FF00',   # Verde
      accent: '#FFFFFF'       # Branco
    },
    'Cruzeiro' => {
      primary: '#003DA5',     # Azul
      secondary: '#FFFFFF',   # Branco
      accent: '#000000'       # Preto
    },
    'Atlético-MG' => {
      primary: '#000000',     # Preto
      secondary: '#FFFFFF',   # Branco
      accent: '#C4C4C4'       # Cinza claro
    },
    'Bahia' => {
      primary: '#0047AB',     # Azul
      secondary: '#FF0000',   # Vermelho
      accent: '#FFFFFF'       # Branco
    },
    'Sport' => {
      primary: '#FF0000',     # Vermelho
      secondary: '#000000',   # Preto
      accent: '#FFFFFF'       # Branco
    },
    'Ceará' => {
      primary: '#000000',     # Preto
      secondary: '#FFFFFF',   # Branco
      accent: '#C4C4C4'       # Cinza claro
    },
    'Fortaleza' => {
      primary: '#FF0000',     # Vermelho
      secondary: '#0047AB',   # Azul
      accent: '#FFFFFF'       # Branco
    },
    # Cores padrão para clubes não mapeados
    'default' => {
      primary: '#228B22',     # Verde padrão
      secondary: '#32CD32',   # Verde claro
      accent: '#FFFFFF'       # Branco
    }
  }.freeze
end
