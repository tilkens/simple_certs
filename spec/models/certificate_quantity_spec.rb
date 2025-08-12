require 'rails_helper'

describe CertificateQuantity do
  let(:generator) { create(:generator) }
  let(:generation) { create(:generation, quantity: 100, generator: generator) }
  let(:certificate) { generation.certificate }
  let(:certificate_quantity) { certificate.certificate_quantities.first }

  describe 'quantity validations' do
    context 'when quantity is zero' do
      subject { build(:certificate_quantity, quantity: 0, certificate: certificate, account: generator.organization.default_account) }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:quantity]).to include('must be greater than 0')
      end
    end

    context 'when quantity is negative' do
      subject { build(:certificate_quantity, quantity: -10, certificate: certificate, account: generator.organization.default_account) }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:quantity]).to include('must be greater than 0')
      end
    end

    context 'when quantity is positive' do
      subject { build(:certificate_quantity, quantity: 50, certificate: certificate, account: generator.organization.default_account) }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe '#split' do
    context 'when splitting with valid quantity' do
      it 'creates a new certificate quantity with remaining amount' do
        original_quantity = certificate_quantity.quantity
        split_amount = 30

        expect {
          certificate_quantity.split(split_amount)
        }.to change(CertificateQuantity, :count).by(1)

        expect(certificate_quantity.reload.quantity).to eq(split_amount)
        expect(CertificateQuantity.last.quantity).to eq(original_quantity - split_amount)
      end

      it 'maintains conservation of quantities' do
        original_total = certificate_quantity.quantity
        split_amount = 40

        certificate_quantity.split(split_amount)

        new_total = certificate_quantity.reload.quantity + CertificateQuantity.last.quantity
        expect(new_total).to eq(original_total)
      end
    end

    context 'when splitting with invalid quantity' do
      it 'raises error for zero quantity' do
        expect { certificate_quantity.split(0) }.to raise_error(ArgumentError, "quantity must be a positive integer")
        expect(CertificateQuantity.count).to eq(1)
      end

      it 'raises error for negative quantity' do
        expect { certificate_quantity.split(-10) }.to raise_error(ArgumentError, "quantity must be a positive integer")
        expect(CertificateQuantity.count).to eq(1)
      end

      it 'raises error for non-integer quantity' do
        expect { certificate_quantity.split(10.5) }.to raise_error(ArgumentError, "quantity must be a positive integer")
        expect(CertificateQuantity.count).to eq(1)
      end

      it 'raises error for quantity equal to or greater than original' do
        expect { certificate_quantity.split(100) }.to raise_error(ArgumentError, "quantity must be less than the original quantity")
        expect { certificate_quantity.split(150) }.to raise_error(ArgumentError, "quantity must be less than the original quantity")
        expect(CertificateQuantity.count).to eq(1)
      end

      it 'raises error for inactive certificate quantity' do
        certificate_quantity.update!(status: "retired")
        expect { certificate_quantity.split(30) }.to raise_error(ArgumentError, "cannot split inactive certificate quantity")
        expect(CertificateQuantity.count).to eq(1)
      end
    end
  end

  describe '#retire' do
    it 'changes status to retired' do
      expect(certificate_quantity.status).to eq('active')

      certificate_quantity.retire

      expect(certificate_quantity.reload.status).to eq('retired')
    end
  end
end
