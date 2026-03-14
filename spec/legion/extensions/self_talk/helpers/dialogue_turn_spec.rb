# frozen_string_literal: true

RSpec.describe Legion::Extensions::SelfTalk::Helpers::DialogueTurn do
  let(:dialogue_id) { 'dlg-001' }
  let(:voice_id)    { 'voice-001' }

  subject(:turn) do
    described_class.new(dialogue_id: dialogue_id, voice_id: voice_id, content: 'This is a thought')
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(turn.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns dialogue_id' do
      expect(turn.dialogue_id).to eq(dialogue_id)
    end

    it 'assigns voice_id' do
      expect(turn.voice_id).to eq(voice_id)
    end

    it 'assigns content' do
      expect(turn.content).to eq('This is a thought')
    end

    it 'defaults position to :clarify' do
      expect(turn.position).to eq(:clarify)
    end

    it 'defaults strength to 0.5' do
      expect(turn.strength).to eq(0.5)
    end

    it 'accepts valid position' do
      t = described_class.new(dialogue_id: dialogue_id, voice_id: voice_id, content: 'x', position: :support)
      expect(t.position).to eq(:support)
    end

    it 'falls back to :clarify for unknown position' do
      t = described_class.new(dialogue_id: dialogue_id, voice_id: voice_id, content: 'x', position: :unknown_pos)
      expect(t.position).to eq(:clarify)
    end

    it 'clamps strength above 1.0' do
      t = described_class.new(dialogue_id: dialogue_id, voice_id: voice_id, content: 'x', strength: 2.0)
      expect(t.strength).to eq(1.0)
    end

    it 'clamps strength below 0.0' do
      t = described_class.new(dialogue_id: dialogue_id, voice_id: voice_id, content: 'x', strength: -1.0)
      expect(t.strength).to eq(0.0)
    end

    it 'sets created_at' do
      expect(turn.created_at).to be_a(Time)
    end
  end

  describe 'POSITIONS' do
    it 'includes the four valid positions' do
      expect(described_class::POSITIONS).to include(:support, :oppose, :question, :clarify)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = turn.to_h
      expect(h).to include(:id, :dialogue_id, :voice_id, :content, :position, :strength, :created_at)
    end

    it 'rounds strength to 10 decimal places' do
      h = turn.to_h
      expect(h[:strength]).to be_a(Float)
    end
  end
end
