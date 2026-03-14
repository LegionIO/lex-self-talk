# frozen_string_literal: true

RSpec.describe Legion::Extensions::SelfTalk::Helpers::Dialogue do
  subject(:dialogue) { described_class.new(topic: 'Should I refactor the cache layer?') }

  let(:voice_id) { 'voice-abc' }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(dialogue.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns topic' do
      expect(dialogue.topic).to eq('Should I refactor the cache layer?')
    end

    it 'starts with empty turns' do
      expect(dialogue.turns).to be_empty
    end

    it 'starts with :open status' do
      expect(dialogue.status).to eq(:open)
    end

    it 'starts with nil conclusion' do
      expect(dialogue.conclusion).to be_nil
    end

    it 'sets created_at' do
      expect(dialogue.created_at).to be_a(Time)
    end
  end

  describe '#add_turn!' do
    it 'adds a turn and returns the DialogueTurn' do
      turn = dialogue.add_turn!(voice_id: voice_id, content: 'Yes, it needs refactoring')
      expect(turn).to be_a(Legion::Extensions::SelfTalk::Helpers::DialogueTurn)
      expect(dialogue.turn_count).to eq(1)
    end

    it 'returns false when dialogue is not active' do
      dialogue.conclude!('done')
      result = dialogue.add_turn!(voice_id: voice_id, content: 'Late thought')
      expect(result).to be false
    end

    it 'returns false when turn limit is reached' do
      stub_const('Legion::Extensions::SelfTalk::Helpers::Constants::MAX_TURNS_PER_DIALOGUE', 2)
      dialogue.add_turn!(voice_id: voice_id, content: 'Turn 1')
      dialogue.add_turn!(voice_id: voice_id, content: 'Turn 2')
      result = dialogue.add_turn!(voice_id: voice_id, content: 'Turn 3')
      expect(result).to be false
    end

    it 'accepts position and strength' do
      turn = dialogue.add_turn!(voice_id: voice_id, content: 'Oppose it', position: :oppose, strength: 0.8)
      expect(turn.position).to eq(:oppose)
      expect(turn.strength).to eq(0.8)
    end
  end

  describe '#conclude!' do
    it 'sets status to :concluded and stores summary' do
      dialogue.conclude!('We should refactor')
      expect(dialogue.status).to eq(:concluded)
      expect(dialogue.conclusion).to eq('We should refactor')
    end

    it 'returns true on success' do
      expect(dialogue.conclude!('done')).to be true
    end

    it 'returns false if already concluded' do
      dialogue.conclude!('first')
      expect(dialogue.conclude!('second')).to be false
    end
  end

  describe '#deadlock!' do
    it 'sets status to :deadlocked' do
      dialogue.deadlock!
      expect(dialogue.status).to eq(:deadlocked)
    end

    it 'returns true on success' do
      expect(dialogue.deadlock!).to be true
    end

    it 'returns false if not active' do
      dialogue.conclude!('done')
      expect(dialogue.deadlock!).to be false
    end
  end

  describe '#abandon!' do
    it 'sets status to :abandoned' do
      dialogue.abandon!
      expect(dialogue.status).to eq(:abandoned)
    end

    it 'returns false if already closed' do
      dialogue.deadlock!
      expect(dialogue.abandon!).to be false
    end
  end

  describe '#active?' do
    it 'is true when status is :open' do
      expect(dialogue.active?).to be true
    end

    it 'is false after conclusion' do
      dialogue.conclude!('done')
      expect(dialogue.active?).to be false
    end
  end

  describe '#concluded?' do
    it 'is false initially' do
      expect(dialogue.concluded?).to be false
    end

    it 'is true after conclude!' do
      dialogue.conclude!('done')
      expect(dialogue.concluded?).to be true
    end
  end

  describe '#voice_positions' do
    it 'returns empty hash when no turns' do
      expect(dialogue.voice_positions).to eq({})
    end

    it 'returns average strength per voice' do
      dialogue.add_turn!(voice_id: 'v1', content: 'A', strength: 0.4)
      dialogue.add_turn!(voice_id: 'v1', content: 'B', strength: 0.6)
      positions = dialogue.voice_positions
      expect(positions['v1']).to be_within(0.001).of(0.5)
    end

    it 'tracks multiple voices separately' do
      dialogue.add_turn!(voice_id: 'v1', content: 'A', strength: 0.8)
      dialogue.add_turn!(voice_id: 'v2', content: 'B', strength: 0.2)
      positions = dialogue.voice_positions
      expect(positions['v1']).to be > positions['v2']
    end
  end

  describe '#consensus_score' do
    it 'returns 1.0 when no turns' do
      expect(dialogue.consensus_score).to eq(1.0)
    end

    it 'returns 0.5 when no support or oppose turns' do
      dialogue.add_turn!(voice_id: voice_id, content: 'A question', position: :question)
      expect(dialogue.consensus_score).to eq(0.5)
    end

    it 'returns high score when all turns support' do
      dialogue.add_turn!(voice_id: voice_id, content: 'Support 1', position: :support, strength: 0.9)
      dialogue.add_turn!(voice_id: voice_id, content: 'Support 2', position: :support, strength: 0.8)
      expect(dialogue.consensus_score).to eq(1.0)
    end

    it 'returns ~0.5 when support and oppose are balanced' do
      dialogue.add_turn!(voice_id: 'v1', content: 'Support', position: :support, strength: 0.5)
      dialogue.add_turn!(voice_id: 'v2', content: 'Oppose', position: :oppose, strength: 0.5)
      expect(dialogue.consensus_score).to be_within(0.01).of(0.5)
    end
  end

  describe '#consensus_label' do
    it 'returns a symbol from CONSENSUS_LABELS' do
      valid = %i[unanimous agreement mixed disagreement conflict]
      expect(valid).to include(dialogue.consensus_label)
    end
  end

  describe '#to_h' do
    it 'includes expected keys' do
      h = dialogue.to_h
      expect(h).to include(:id, :topic, :status, :conclusion, :turn_count, :consensus_score, :consensus_label, :created_at, :turns)
    end

    it 'turns is an array' do
      dialogue.add_turn!(voice_id: voice_id, content: 'x')
      expect(dialogue.to_h[:turns]).to be_an(Array)
      expect(dialogue.to_h[:turns].size).to eq(1)
    end
  end
end
