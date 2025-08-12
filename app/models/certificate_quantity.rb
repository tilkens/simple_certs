class CertificateQuantity < ApplicationRecord
  belongs_to :certificate
  belongs_to :account
  belongs_to :to_organization, class_name: "Organization", foreign_key: "to_organization_id", optional: true

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def split(quantity)
    raise ArgumentError, "cannot split inactive certificate quantity" unless status == "active"

    if quantity.is_a?(String)
      raise ArgumentError, "quantity must be a valid positive integer" unless quantity.match?(/^\d+$/)
      quantity = quantity.to_i
    end

    raise ArgumentError, "quantity must be a positive integer" unless quantity.is_a?(Integer) && quantity > 0
    raise ArgumentError, "quantity must be less than the original quantity" unless quantity < self.quantity

    self.class.create!(
      certificate: certificate,
      account: account,
      quantity: self.quantity - quantity,
      status: "active"
    )

    update!(quantity: quantity)
  end

  def retire
    update(status: "retired")
  end
end
