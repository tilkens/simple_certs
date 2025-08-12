require 'rails_helper'

RSpec.describe 'Certificates', type: :request do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:generator) { create(:generator, organization: organization) }
  let(:other_generator) { create(:generator, organization: other_organization) }
  let!(:generation) { create(:generation, generator: generator) }
  let!(:other_generation) { create(:generation, generator: other_generator) }
  let(:certificate) { generation.certificate }
  let(:other_certificate) { other_generation.certificate }

  let(:json_headers) {
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  }
  let(:user_header) {
    { 'X-Api-Key' => user.api_key }
  }
  let(:headers) {
    json_headers.merge(user_header)
  }

  def certificate_json(certificate)
    {
      'id' => certificate.id,
      'sn_base' => certificate.sn_base,
      'quantity' => certificate.quantity,
      'generator_id' => certificate.generator_id,
      'generation_id' => certificate.generation_id
    }
  end

  context 'index' do
    before do
      get '/certificates', headers: headers
    end

    it 'has a 200 status' do
      expect(response.status).to eq(200)
    end

    it 'returns certificates' do
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'certificates' => [ certificate_json(certificate) ]
        }
      )
    end
  end

  context 'show' do
    context "when accessing certificate that is associated with user's organization" do
      it 'returns a certificate' do
        get "/certificates/#{certificate.id}", headers: headers
        json = JSON.parse(response.body)
        expect(json).to eq(certificate_json(certificate))
      end
    end

    context "when accessing certificate that is not associated with user's organization" do
      it 'returns an unauthorized status' do
        get "/certificates/#{other_certificate.id}", headers: headers
        expect(response.code).to eq('401')
      end
    end
  end
end
