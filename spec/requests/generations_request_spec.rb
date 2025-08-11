require 'rails_helper'

RSpec.describe 'Generations', type: :request do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:generator) { create(:generator, organization: organization) }
  let(:other_generator) { create(:generator, organization: other_organization) }

  let(:json_headers) {
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  }
  let(:user_header) {
    { 'X-Api-Key' => user.api_key }
  }
  let(:headers) {
    json_headers.merge(user_header)
  }

  def generation_json(generation)
    {
      'id' => generation.id,
      'start_date' => generation.start_date&.iso8601,
      'end_date' => generation.end_date&.iso8601,
      'quantity' => generation.quantity,
      'generator_id' => generation.generator_id
    }
  end

  context 'index' do
    let!(:generation) { create(:generation, generator: generator) }
    let!(:other_generation) { create(:generation, generator: other_generator) }

    before do
      get '/generations', headers: headers
    end

    it 'has a 200 status' do
      expect(response.status).to eq(200)
    end

    it 'returns generations' do
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'generations' => [ generation_json(generation) ]
        }
      )
    end
  end

  context 'show' do
    context "when accessing generation that is associated with user's organization" do
      let!(:generation) { create(:generation, generator: generator) }
      it 'returns a generation' do
        get "/generations/#{generation.id}", headers: headers
        json = JSON.parse(response.body)
        expect(json).to eq(generation_json(generation))
      end
    end

    context "when accessing generation that is not associated with user's organization" do
      let!(:generation) { create(:generation, generator: other_generator) }
      it 'returns an unauthorized status' do
        get "/generations/#{generation.id}", headers: headers
        expect(response.code).to eq('401')
      end
    end
  end

  context 'create' do
    let(:body) {
      {
        'start_date'  => Date.new(2025, 2, 1),
        'end_date' => Date.new(2025, 2, 28),
        'quantity' => 80,
        'generator_id' => create_generator.id
      }
    }

    before do
      post '/generations', headers: headers, params: body.to_json
    end

    context "when creating generation that is associated with a generator in the user's organization" do
      let(:create_generator) { generator }

      it 'creates a generation' do
        expect(Generation.count).to eq(1)
      end

      it 'has the correct status' do
        expect(response.status).to eq(201)
      end

      it 'creates the generation with the correct data' do
        json = JSON.parse(response.body)
        generation = Generation.find(json['id'])
        attrs = generation.attributes.slice(*%w[start_date end_date quantity generator_id])
        expect(attrs).to eq(body)
      end

      it 'returns the body with the correct body' do
        json = JSON.parse(response.body)
        generation = Generation.find(json['id'])
        expect(json).to eq(generation_json(generation))
      end
    end


    context "when creating generation that is NOT associated with a generator in the user's organization" do
      let(:create_generator) { other_generator }

      it 'returns and unauthorized status' do
        expect(response.code).to eq('401')
      end
    end
  end

  context "when creating a generation that overlaps with an existing generation" do
    let(:create_generator) { create(:generator, organization: organization) }
    let!(:existing_generation) { create(:generation, generator: create_generator, quantity: 100, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 1, 31)) }
    let(:body) {
      {
        'start_date'  => Date.new(2025, 1, 15),
        'end_date' => Date.new(2025, 1, 28),
        'quantity' => 80,
        'generator_id' => create_generator.id
      }
    }

    it 'returns an unprocessable entity error' do
      post '/generations', headers: headers, params: body.to_json
      expect(response.code).to eq('422')
      json = JSON.parse(response.body)
      expect(json['errors']).to include("generation dates overlap with existing generation")
      expect(json['errors']).to include("generation must be contiguous with an existing generation")
    end
  end
end
