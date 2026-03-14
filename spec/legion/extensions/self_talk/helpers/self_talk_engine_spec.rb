# frozen_string_literal: true

RSpec.describe Legion::Extensions::SelfTalk::Helpers::SelfTalkEngine do
  subject(:engine) { described_class.new }

  def add_voice(name: 'TestVoice', type: :analyst, volume: 0.5)
    result = engine.register_voice(name: name, voice_type: type, volume: volume)
    result[:voice][:id]
  end

  def add_dialogue(topic: 'Test topic')
    result = engine.start_dialogue(topic: topic)
    result[:dialogue][:id]
  end

  describe '#register_voice' do
    it 'registers a valid voice' do
      result = engine.register_voice(name: 'Critic', voice_type: :critic)
      expect(result[:registered]).to be true
      expect(result[:voice][:name]).to eq('Critic')
    end

    it 'returns unknown_type for invalid voice_type' do
      result = engine.register_voice(name: 'X', voice_type: :unknown_type)
      expect(result[:registered]).to be false
      expect(result[:reason]).to eq(:unknown_type)
    end

    it 'returns max_voices when limit reached' do
      stub_const('Legion::Extensions::SelfTalk::Helpers::Constants::MAX_VOICES', 1)
      engine.register_voice(name: 'First', voice_type: :critic)
      result = engine.register_voice(name: 'Second', voice_type: :analyst)
      expect(result[:registered]).to be false
      expect(result[:reason]).to eq(:max_voices)
    end

    it 'stores all registered voices' do
      add_voice(name: 'V1', type: :critic)
      add_voice(name: 'V2', type: :encourager)
      expect(engine.voices.size).to eq(2)
    end
  end

  describe '#start_dialogue' do
    it 'creates a dialogue with the given topic' do
      result = engine.start_dialogue(topic: 'What should I do?')
      expect(result[:started]).to be true
      expect(result[:dialogue][:topic]).to eq('What should I do?')
    end

    it 'stores the dialogue' do
      add_dialogue
      expect(engine.dialogues.size).to eq(1)
    end

    it 'prunes oldest dialogue when MAX_DIALOGUES is reached' do
      stub_const('Legion::Extensions::SelfTalk::Helpers::Constants::MAX_DIALOGUES', 2)
      id1 = add_dialogue(topic: 'First')
      add_dialogue(topic: 'Second')
      add_dialogue(topic: 'Third')
      expect(engine.dialogues.key?(id1)).to be false
      expect(engine.dialogues.size).to eq(2)
    end
  end

  describe '#add_turn' do
    let(:voice_id)    { add_voice }
    let(:dialogue_id) { add_dialogue }

    it 'adds a turn successfully' do
      result = engine.add_turn(dialogue_id: dialogue_id, voice_id: voice_id, content: 'My thought')
      expect(result[:added]).to be true
    end

    it 'returns dialogue_not_found for unknown dialogue' do
      result = engine.add_turn(dialogue_id: 'bad-id', voice_id: voice_id, content: 'x')
      expect(result[:reason]).to eq(:dialogue_not_found)
    end

    it 'returns voice_not_found for unknown voice' do
      result = engine.add_turn(dialogue_id: dialogue_id, voice_id: 'bad-voice', content: 'x')
      expect(result[:reason]).to eq(:voice_not_found)
    end

    it 'returns voice_inactive when voice is muted' do
      engine.voices[voice_id].mute!
      result = engine.add_turn(dialogue_id: dialogue_id, voice_id: voice_id, content: 'x')
      expect(result[:reason]).to eq(:voice_inactive)
    end
  end

  describe '#conclude_dialogue' do
    it 'concludes an open dialogue' do
      id = add_dialogue
      result = engine.conclude_dialogue(dialogue_id: id, summary: 'Decision made')
      expect(result[:concluded]).to be true
    end

    it 'returns not_found for unknown dialogue' do
      result = engine.conclude_dialogue(dialogue_id: 'bad', summary: 'x')
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#deadlock_dialogue' do
    it 'deadlocks an open dialogue' do
      id = add_dialogue
      result = engine.deadlock_dialogue(dialogue_id: id)
      expect(result[:deadlocked]).to be true
    end

    it 'returns not_found for unknown dialogue' do
      result = engine.deadlock_dialogue(dialogue_id: 'bad')
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#active_dialogues' do
    it 'returns only open dialogues' do
      id1 = add_dialogue(topic: 'Open')
      id2 = add_dialogue(topic: 'Concluded')
      engine.conclude_dialogue(dialogue_id: id2, summary: 'done')
      expect(engine.active_dialogues.map { |d| d.to_h[:id] }).to include(id1)
      expect(engine.active_dialogues.map { |d| d.to_h[:id] }).not_to include(id2)
    end
  end

  describe '#concluded_dialogues' do
    it 'returns only concluded dialogues' do
      id = add_dialogue(topic: 'Test')
      engine.conclude_dialogue(dialogue_id: id, summary: 'done')
      expect(engine.concluded_dialogues.size).to eq(1)
    end
  end

  describe '#dominant_voice' do
    it 'returns nil when no voices' do
      expect(engine.dominant_voice).to be_nil
    end

    it 'returns the voice with highest volume' do
      add_voice(name: 'Low', type: :critic, volume: 0.2)
      add_voice(name: 'High', type: :encourager, volume: 0.9)
      expect(engine.dominant_voice.name).to eq('High')
    end

    it 'ignores inactive voices' do
      id1 = add_voice(name: 'Loud', type: :analyst, volume: 0.9)
      add_voice(name: 'Quiet', type: :rebel, volume: 0.3)
      engine.voices[id1].mute!
      expect(engine.dominant_voice.name).to eq('Quiet')
    end
  end

  describe '#quietest_voice' do
    it 'returns nil when no voices' do
      expect(engine.quietest_voice).to be_nil
    end

    it 'returns the voice with lowest volume' do
      add_voice(name: 'Low', type: :critic, volume: 0.2)
      add_voice(name: 'High', type: :encourager, volume: 0.9)
      expect(engine.quietest_voice.name).to eq('Low')
    end
  end

  describe '#voice_balance' do
    it 'returns empty hash when no voices' do
      expect(engine.voice_balance).to eq({})
    end

    it 'returns proportional volumes' do
      add_voice(name: 'V1', type: :critic, volume: 0.5)
      add_voice(name: 'V2', type: :analyst, volume: 0.5)
      balance = engine.voice_balance
      expect(balance.values.sum).to be_within(0.001).of(1.0)
    end
  end

  describe '#amplify_voice' do
    it 'increases voice volume' do
      id = add_voice(volume: 0.5)
      result = engine.amplify_voice(voice_id: id, amount: 0.1)
      expect(result[:amplified]).to be true
      expect(result[:volume]).to be_within(0.001).of(0.6)
    end

    it 'returns not_found for unknown voice' do
      result = engine.amplify_voice(voice_id: 'bad')
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#dampen_voice' do
    it 'decreases voice volume' do
      id = add_voice(volume: 0.5)
      result = engine.dampen_voice(voice_id: id, amount: 0.1)
      expect(result[:dampened]).to be true
      expect(result[:volume]).to be_within(0.001).of(0.4)
    end

    it 'returns not_found for unknown voice' do
      result = engine.dampen_voice(voice_id: 'bad')
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#dialogue_report' do
    it 'returns found: false for unknown dialogue' do
      expect(engine.dialogue_report(dialogue_id: 'bad')[:found]).to be false
    end

    it 'returns the dialogue and voice positions' do
      vid = add_voice(name: 'Analyst')
      did = add_dialogue
      engine.add_turn(dialogue_id: did, voice_id: vid, content: 'Thought', position: :support, strength: 0.7)
      report = engine.dialogue_report(dialogue_id: did)
      expect(report[:found]).to be true
      expect(report[:dialogue]).to be_a(Hash)
      expect(report[:voice_positions]).to be_a(Hash)
      expect(report[:voice_positions]['Analyst']).to be_within(0.001).of(0.7)
    end
  end

  describe '#to_h' do
    it 'returns summary hash' do
      h = engine.to_h
      expect(h).to include(:voice_count, :dialogue_count, :active_dialogue_count, :dominant_voice, :quietest_voice, :voice_balance)
    end

    it 'reflects registered voices and dialogues' do
      add_voice
      add_dialogue
      h = engine.to_h
      expect(h[:voice_count]).to eq(1)
      expect(h[:dialogue_count]).to eq(1)
    end
  end
end
