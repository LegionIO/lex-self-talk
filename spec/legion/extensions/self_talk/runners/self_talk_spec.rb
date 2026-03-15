# frozen_string_literal: true

require 'legion/extensions/self_talk/client'

RSpec.describe Legion::Extensions::SelfTalk::Runners::SelfTalk do
  let(:client) { Legion::Extensions::SelfTalk::Client.new }

  def register_voice(name: 'Test', type: :analyst)
    result = client.register_voice(name: name, voice_type: type)
    result[:voice][:id]
  end

  def start_dialogue(topic: 'Test topic')
    result = client.start_dialogue(topic: topic)
    result[:dialogue][:id]
  end

  describe '#register_voice' do
    it 'registers a valid voice' do
      result = client.register_voice(name: 'Critic', voice_type: :critic)
      expect(result[:registered]).to be true
    end

    it 'includes voice data in result' do
      result = client.register_voice(name: 'Encourager', voice_type: :encourager)
      expect(result[:voice][:name]).to eq('Encourager')
      expect(result[:voice][:voice_type]).to eq(:encourager)
    end

    it 'rejects unknown voice type' do
      result = client.register_voice(name: 'X', voice_type: :bogus)
      expect(result[:registered]).to be false
    end

    it 'accepts bias_direction' do
      result = client.register_voice(name: 'Pragmatist', voice_type: :pragmatist, bias_direction: :practical)
      expect(result[:registered]).to be true
    end
  end

  describe '#start_dialogue' do
    it 'starts a new dialogue' do
      result = client.start_dialogue(topic: 'Shall we proceed?')
      expect(result[:started]).to be true
      expect(result[:dialogue][:topic]).to eq('Shall we proceed?')
    end

    it 'returns a dialogue with a UUID id' do
      result = client.start_dialogue(topic: 'x')
      expect(result[:dialogue][:id]).to match(/\A[0-9a-f-]{36}\z/)
    end
  end

  describe '#add_turn' do
    it 'adds a turn with valid voice and dialogue' do
      vid = register_voice
      did = start_dialogue
      result = client.add_turn(dialogue_id: did, voice_id: vid, content: 'A thought')
      expect(result[:added]).to be true
    end

    it 'returns not found reason for bad dialogue' do
      vid = register_voice
      result = client.add_turn(dialogue_id: 'bad', voice_id: vid, content: 'x')
      expect(result[:added]).to be false
      expect(result[:reason]).to eq(:dialogue_not_found)
    end

    it 'returns not found reason for bad voice' do
      did = start_dialogue
      result = client.add_turn(dialogue_id: did, voice_id: 'bad', content: 'x')
      expect(result[:added]).to be false
      expect(result[:reason]).to eq(:voice_not_found)
    end

    it 'accepts position and strength' do
      vid = register_voice
      did = start_dialogue
      result = client.add_turn(dialogue_id: did, voice_id: vid, content: 'x', position: :oppose, strength: 0.9)
      expect(result[:added]).to be true
      expect(result[:turn][:position]).to eq(:oppose)
    end
  end

  describe '#conclude_dialogue' do
    it 'concludes an open dialogue' do
      did = start_dialogue
      result = client.conclude_dialogue(dialogue_id: did, summary: 'Agreed')
      expect(result[:concluded]).to be true
    end

    it 'returns not_found for unknown dialogue' do
      result = client.conclude_dialogue(dialogue_id: 'nope', summary: 'x')
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#deadlock_dialogue' do
    it 'deadlocks an open dialogue' do
      did = start_dialogue
      result = client.deadlock_dialogue(dialogue_id: did)
      expect(result[:deadlocked]).to be true
    end

    it 'returns not_found for unknown dialogue' do
      result = client.deadlock_dialogue(dialogue_id: 'nope')
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#amplify_voice' do
    it 'increases voice volume' do
      vid = register_voice
      client.amplify_voice(voice_id: vid, amount: 0.2)
      result = client.amplify_voice(voice_id: vid, amount: 0.0)
      expect(result[:amplified]).to be true
    end

    it 'returns not_found for unknown voice' do
      result = client.amplify_voice(voice_id: 'nope')
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#dampen_voice' do
    it 'decreases voice volume' do
      vid = register_voice
      result = client.dampen_voice(voice_id: vid, amount: 0.1)
      expect(result[:dampened]).to be true
    end

    it 'returns not_found for unknown voice' do
      result = client.dampen_voice(voice_id: 'nope')
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#dialogue_report' do
    it 'returns found: false for unknown dialogue' do
      result = client.dialogue_report(dialogue_id: 'nope')
      expect(result[:found]).to be false
    end

    it 'returns dialogue and voice positions' do
      vid = register_voice(name: 'Analyst')
      did = start_dialogue(topic: 'Report test')
      client.add_turn(dialogue_id: did, voice_id: vid, content: 'Strong opinion', position: :support, strength: 0.8)
      result = client.dialogue_report(dialogue_id: did)
      expect(result[:found]).to be true
      expect(result[:voice_positions]).to be_a(Hash)
    end
  end

  describe '#self_talk_status' do
    it 'returns summary hash' do
      result = client.self_talk_status
      expect(result).to include(:voice_count, :dialogue_count, :active_dialogue_count)
    end

    it 'reflects registered voices' do
      register_voice
      result = client.self_talk_status
      expect(result[:voice_count]).to eq(1)
    end
  end

  describe '#decay_voices' do
    it 'returns decayed count and voices array' do
      register_voice
      result = client.decay_voices
      expect(result).to include(:decayed, :voices)
    end

    it 'decrements volume on active voices' do
      vid = register_voice
      client.amplify_voice(voice_id: vid, amount: 0.3)
      result = client.decay_voices
      expect(result[:decayed]).to eq(1)
      expect(result[:voices].first[:volume]).to be < 1.0
    end

    it 'returns zero decayed when no voices registered' do
      result = client.decay_voices
      expect(result[:decayed]).to eq(0)
      expect(result[:voices]).to eq([])
    end

    it 'includes id, name, and volume in each voice entry' do
      register_voice(name: 'Critic', type: :critic)
      result = client.decay_voices
      voice = result[:voices].first
      expect(voice).to include(:id, :name, :volume)
      expect(voice[:name]).to eq('Critic')
    end
  end
end
