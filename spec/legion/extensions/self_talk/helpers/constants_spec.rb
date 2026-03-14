# frozen_string_literal: true

RSpec.describe Legion::Extensions::SelfTalk::Helpers::Constants do
  describe 'MAX_VOICES' do
    it 'is 10' do
      expect(described_class::MAX_VOICES).to eq(10)
    end
  end

  describe 'MAX_DIALOGUES' do
    it 'is 200' do
      expect(described_class::MAX_DIALOGUES).to eq(200)
    end
  end

  describe 'MAX_TURNS_PER_DIALOGUE' do
    it 'is 50' do
      expect(described_class::MAX_TURNS_PER_DIALOGUE).to eq(50)
    end
  end

  describe 'DEFAULT_VOLUME' do
    it 'is 0.5' do
      expect(described_class::DEFAULT_VOLUME).to eq(0.5)
    end
  end

  describe 'VOLUME_BOOST' do
    it 'is 0.1' do
      expect(described_class::VOLUME_BOOST).to eq(0.1)
    end
  end

  describe 'VOLUME_DECAY' do
    it 'is 0.05' do
      expect(described_class::VOLUME_DECAY).to eq(0.05)
    end
  end

  describe 'VOICE_TYPES' do
    it 'includes all eight voice types' do
      expect(described_class::VOICE_TYPES).to include(
        :critic, :encourager, :analyst, :devils_advocate,
        :pragmatist, :visionary, :caretaker, :rebel
      )
    end

    it 'is frozen' do
      expect(described_class::VOICE_TYPES).to be_frozen
    end
  end

  describe 'DIALOGUE_STATUSES' do
    it 'includes open, concluded, deadlocked, abandoned' do
      expect(described_class::DIALOGUE_STATUSES).to include(:open, :concluded, :deadlocked, :abandoned)
    end

    it 'is frozen' do
      expect(described_class::DIALOGUE_STATUSES).to be_frozen
    end
  end

  describe '.dominance_label' do
    it 'returns :commanding for volume >= 0.8' do
      expect(described_class.dominance_label(1.0)).to eq(:commanding)
      expect(described_class.dominance_label(0.8)).to eq(:commanding)
    end

    it 'returns :assertive for volume in 0.6..0.8' do
      expect(described_class.dominance_label(0.7)).to eq(:assertive)
    end

    it 'returns :balanced for volume in 0.4..0.6' do
      expect(described_class.dominance_label(0.5)).to eq(:balanced)
    end

    it 'returns :quiet for volume in 0.2..0.4' do
      expect(described_class.dominance_label(0.3)).to eq(:quiet)
    end

    it 'returns :silent for volume < 0.2' do
      expect(described_class.dominance_label(0.1)).to eq(:silent)
      expect(described_class.dominance_label(0.0)).to eq(:silent)
    end
  end

  describe '.consensus_label' do
    it 'returns :unanimous for score >= 0.8' do
      expect(described_class.consensus_label(1.0)).to eq(:unanimous)
      expect(described_class.consensus_label(0.8)).to eq(:unanimous)
    end

    it 'returns :agreement for score in 0.6..0.8' do
      expect(described_class.consensus_label(0.7)).to eq(:agreement)
    end

    it 'returns :mixed for score in 0.4..0.6' do
      expect(described_class.consensus_label(0.5)).to eq(:mixed)
    end

    it 'returns :disagreement for score in 0.2..0.4' do
      expect(described_class.consensus_label(0.3)).to eq(:disagreement)
    end

    it 'returns :conflict for score < 0.2' do
      expect(described_class.consensus_label(0.1)).to eq(:conflict)
      expect(described_class.consensus_label(0.0)).to eq(:conflict)
    end
  end
end
