class Generation < ApplicationRecord
  belongs_to :generator
  has_one :certificate

  scope :for_organization, ->(org) { joins(:generator).where(generators: { organization_id: org.id }) }

  after_create :issue_certificate

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :quantity, presence: true

  validate :start_date_is_less_than_end_date
  validate :start_date_is_not_in_the_future
  validate :end_date_is_not_in_the_future
  validate :no_overlapping_dates
  validate :contiguous_with_existing_generations

  private

  def issue_certificate
    self.certificate = Certificate.new(
      quantity: self.quantity,
      generator: self.generator
    )
  end

  def start_date_is_less_than_end_date
    if start_date > end_date
      errors.add(:base, "start date #{start_date} is not less the than end date #{end_date}")
    end
  end

  def start_date_is_not_in_the_future
    if start_date > Date.today
      errors.add(:base, "start date #{start_date} is in the future")
    end
  end

  def end_date_is_not_in_the_future
    if end_date > Date.today
      errors.add(:base, "end date #{end_date} is in the future")
    end
  end

  def no_overlapping_dates
    overlapping_generation = generator.generations
      .where.not(id: id)
      .where("start_date < ? AND end_date > ?", end_date, start_date).exists?

    if overlapping_generation
      errors.add(:base, "generation dates overlap with existing generation")
    end
  end

  def contiguous_with_existing_generations
    existing_generations = generator.generations.where.not(id: id)
    return if existing_generations.empty?

    connects_to_timeline = existing_generations
      .where("end_date = ? OR start_date = ?", start_date - 1.day, end_date + 1.day)
      .exists?

    unless connects_to_timeline
      errors.add(:base, "generation must be contiguous with an existing generation")
    end
  end
end
