class Certificate < ApplicationRecord
  belongs_to :generator
  belongs_to :generation
  has_many :certificate_quantities

  validate :certificate_quantities_conservation

  before_save :assign_vintage_date
  before_save :assign_serial_number
  after_create :create_certificate_quantity

  def assign_vintage_date
    self.vintage_date = generation.end_date.beginning_of_month
  end

  def assign_serial_number
    self.sn_base = "#{vintage_date.strftime('%Y-%m')}-#{SecureRandom.hex[0..7]}"
  end

  def create_certificate_quantity
    self.certificate_quantities << CertificateQuantity.new(
      quantity: quantity,
      account: generator.organization.default_account,
      status: "active"
    )
  end

  private

  def certificate_quantities_conservation
    return if certificate_quantities.empty?

    total_quantity = certificate_quantities.sum(:quantity)
    if total_quantity != quantity
      errors.add(:base, "sum of certificate quantities (#{total_quantity}) must equal certificate quantity (#{quantity})")
    end
  end
end
