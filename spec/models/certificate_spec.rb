require 'rails_helper'

describe Certificate do
  let(:generator) { create(:generator) }
  let(:generation) { create(:generation, quantity: 5, generator: generator) }
  subject { generation.certificate }

  it 'sets the serial number base correctly' do
    expect(subject.sn_base).to match(/^#{subject.vintage_date.strftime('%Y-%m')}/)
  end

  it 'creates a certificate quantity with the same quantity' do
    expect(subject.certificate_quantities.map(&:quantity)).to eq([ 5 ])
  end

  it 'puts the certificate in the organizations default account' do
    expect(subject.certificate_quantities.map(&:account_id)).to eq([ generator.organization.default_account_id ])
  end

  describe 'certificate quantities conservation' do
    let(:certificate) { generation.certificate }
    let!(:certificate_quantity) { certificate.certificate_quantities.first }

    context 'when quantities are conserved' do
      it 'is valid' do
        expect(certificate).to be_valid
      end
    end

    context 'when quantities are not conserved' do
      before do
        certificate_quantity.update!(quantity: 50)
      end

      it 'is not valid' do
        expect(certificate).not_to be_valid
        expect(certificate.errors[:base]).to include('sum of certificate quantities (50) must equal certificate quantity (5)')
      end
    end

    context 'when certificate quantities are empty' do
      before do
        certificate.certificate_quantities.destroy_all
      end

      it 'is valid (allows empty state during creation)' do
        expect(certificate).to be_valid
      end
    end
  end
end
