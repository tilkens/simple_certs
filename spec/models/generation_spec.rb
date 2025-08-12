require 'rails_helper'

describe Generation do
  context 'when testing start and end dates' do
    subject { build(:generation, start_date: start_date, end_date: end_date) }

    context 'when start date is before the end date' do
      let(:start_date) { 2.days.ago }
      let(:end_date) { 1.day.ago }

      it 'be valid' do
        expect(subject).to be_valid
      end
    end

    context 'when start date is equal to the end date' do
      let(:start_date) { 1.days.ago }
      let(:end_date) { 1.day.ago }

      it 'be valid' do
        expect(subject).to be_valid
      end
    end

    context 'when start date is after the end date' do
      let(:start_date) { 1.days.ago }
      let(:end_date) { 2.day.ago }

      it 'not be valid' do
        expect(subject).not_to be_valid
      end
    end

    context 'when the end date is in the future' do
      let(:start_date) { 1.days.ago }
      let(:end_date) { 1.day.from_now }

      it 'not be valid' do
        expect(subject).not_to be_valid
      end
    end

    context 'when the start date is in the future' do
      let(:start_date) { 1.days.from_now }
      let(:end_date) { 2.days.from_now }

      it 'not be valid' do
        expect(subject).not_to be_valid
      end
    end
  end

  describe 'date overlap and gap validations' do
    let(:generator) { create(:generator) }
    let!(:existing_generation) { create(:generation, generator: generator, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 1, 31)) }

    context 'when new generation start is not contiguous with existing generation end' do
      subject { build(:generation, generator: generator, start_date: start_date, end_date: end_date) }
      let(:start_date) { Date.new(2025, 2, 2) }  # Jan 31 + 2 days (gap)
      let(:end_date) { Date.new(2025, 2, 28) }

      it 'prevents generation that starts more than one day after existing generation ends' do
        expect(subject).not_to be_valid
        expect(subject.errors[:base]).to include('generation must be contiguous with an existing generation')
      end
    end

    context 'when new generation end is not contiguous with existing generation start' do
      subject { build(:generation, generator: generator, start_date: start_date, end_date: end_date) }
      let(:start_date) { Date.new(2024, 12, 1) }
      let(:end_date) { Date.new(2024, 12, 30) }  # Dec 30 + 1 day != Jan 1

      it 'prevents generation that ends more than one day before existing generation starts' do
        expect(subject).not_to be_valid
        expect(subject.errors[:base]).to include('generation must be contiguous with an existing generation')
      end
    end

    context 'when new generation start is contiguous with existing generation end' do
      subject { build(:generation, generator: generator, start_date: start_date, end_date: end_date) }
      let(:start_date) { Date.new(2025, 2, 1) }  # Jan 31 + 1 day
      let(:end_date) { Date.new(2025, 2, 28) }

      it 'allows generation that starts exactly one day after existing generation ends' do
        expect(subject).to be_valid
      end
    end

    context 'when new generation end is contiguous with existing generation start' do
      subject { build(:generation, generator: generator, start_date: start_date, end_date: end_date) }
      let(:start_date) { Date.new(2024, 12, 1) }
      let(:end_date) { Date.new(2024, 12, 31) }  # Dec 31 + 1 day = Jan 1

      it 'allows generation that ends exactly one day before existing generation starts' do
        expect(subject).to be_valid
      end
    end

    context 'when new generation date range overlaps existing generation date range' do
      subject { build(:generation, generator: generator, start_date: start_date, end_date: end_date) }

      context 'when generation has identical date range' do
        let(:start_date) { Date.new(2025, 1, 1) }
        let(:end_date) { Date.new(2025, 1, 31) }

        it 'prevents generation' do
          expect(subject).not_to be_valid
          expect(subject.errors[:base]).to include('generation dates overlap with existing generation')
        end
      end

      context 'when generation starts during but ends after existing generation' do
        let(:start_date) { Date.new(2025, 1, 15) }
        let(:end_date) { Date.new(2025, 2, 15) }

        it 'prevents generation' do
          expect(subject).not_to be_valid
          expect(subject.errors[:base]).to include('generation dates overlap with existing generation')
        end
      end

      context 'when generation starts before but ends during existing generation' do
        let(:start_date) { Date.new(2024, 12, 15) }
        let(:end_date) { Date.new(2025, 1, 15) }

        it 'prevents generation' do
          expect(subject).not_to be_valid
          expect(subject.errors[:base]).to include('generation dates overlap with existing generation')
        end
      end

      context 'when generation starts during but ends after existing generation' do
        let(:start_date) { Date.new(2025, 1, 15) }
        let(:end_date) { Date.new(2025, 2, 15) }

        it 'prevents generation that starts during but ends after existing generation' do
          expect(subject).not_to be_valid
          expect(subject.errors[:base]).to include('generation dates overlap with existing generation')
        end
      end

      context 'when generation completely contains existing generation' do
        let(:start_date) { Date.new(2024, 12, 1) }
        let(:end_date) { Date.new(2025, 2, 28) }

        it 'prevents generation that completely contains existing generation' do
          expect(subject).not_to be_valid
          expect(subject.errors[:base]).to include('generation dates overlap with existing generation')
        end
      end

      context 'when generation is completely contained within existing generation' do
        let(:start_date) { Date.new(2025, 1, 15) }
        let(:end_date) { Date.new(2025, 1, 25) }

        it 'prevents generation' do
          expect(subject).not_to be_valid
          expect(subject.errors[:base]).to include('generation dates overlap with existing generation')
        end
      end
    end

    context 'when new generation is the first generation for a generator' do
      subject { build(:generation, generator: new_generator, start_date: start_date, end_date: end_date) }
      let(:new_generator) { create(:generator) }
      let(:start_date) { Date.new(2025, 1, 1) }
      let(:end_date) { Date.new(2025, 1, 31) }

      it 'allows first generation for a generator' do
        expect(subject).to be_valid
      end
    end
  end

  # issue_certificate is called after_create
  describe '#issue_certificate' do
    subject { create(:generation, quantity: 5, certificate: nil) }
    let(:certificate) { subject.certificate }

    it 'creates a certificate with the same quantity as the generation' do
      expect(certificate.quantity).to eq(subject.quantity)
    end

    it 'creates a certificate with the same generator as the generation' do
      expect(certificate.generator).to eq(subject.generator)
    end

    it 'creates a certificate with the vintage as the same month as the end date' do
      expect(certificate.vintage_date).to eq(subject.end_date.beginning_of_month)
    end

    it 'creates a one certificate quantity associated with the created certificate' do
      expect(certificate.certificate_quantities.count).to eq(1)
    end
  end

  describe 'certificate association' do
    let(:generator) { create(:generator) }

    it 'enforces one certificate per generation' do
      generation = create(:generation, generator: generator)

      expect(generation.certificate).to be_present

      second_cert = build(:certificate, generation: generation)
      expect { second_cert.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
