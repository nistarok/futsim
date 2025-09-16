class Season < ApplicationRecord
  belongs_to :division
  belongs_to :room
  has_many :clubs, through: :division

  # Validations
  validates :name, presence: true
  validates :year, presence: true, numericality: {
    greater_than: 1900,
    less_than_or_equal_to: Date.current.year + 10
  }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :status, presence: true, inclusion: {
    in: ['preparation', 'active', 'finished'],
    message: 'deve ser preparation, active ou finished'
  }

  # Custom validation to ensure end_date is after start_date
  validate :end_date_after_start_date

  # Scopes
  scope :by_year, ->(year) { where(year: year) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_room, ->(room) { where(room: room) }
  scope :by_division, ->(division) { where(division: division) }
  scope :active, -> { where(status: 'active') }
  scope :finished, -> { where(status: 'finished') }
  scope :current, -> { where('start_date <= ? AND end_date >= ?', Date.current, Date.current) }

  # Methods
  def active?
    status == 'active'
  end

  def finished?
    status == 'finished'
  end

  def in_preparation?
    status == 'preparation'
  end

  def duration_in_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i
  end

  def progress_percentage
    return 0 unless start_date && end_date && active?
    return 100 if finished?

    total_days = duration_in_days
    return 0 if total_days <= 0

    elapsed_days = (Date.current - start_date).to_i
    [(elapsed_days.to_f / total_days * 100).round(1), 100].min
  end

  def remaining_days
    return 0 unless end_date && active?
    [(end_date - Date.current).to_i, 0].max
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    if end_date <= start_date
      errors.add(:end_date, 'deve ser posterior à data de início')
    end
  end
end
