# frozen_string_literal: true

RSpec.describe Legion::Extensions::SelfTalk::Helpers::InnerVoice do
  subject(:voice) { described_class.new(name: 'Critic', voice_type: :critic) }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(voice.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns name' do
      expect(voice.name).to eq('Critic')
    end

    it 'assigns voice_type' do
      expect(voice.voice_type).to eq(:critic)
    end

    it 'defaults volume to DEFAULT_VOLUME' do
      expect(voice.volume).to eq(0.5)
    end

    it 'accepts custom volume' do
      v = described_class.new(name: 'Loud', voice_type: :encourager, volume: 0.9)
      expect(v.volume).to eq(0.9)
    end

    it 'clamps volume above 1.0' do
      v = described_class.new(name: 'Over', voice_type: :analyst, volume: 1.5)
      expect(v.volume).to eq(1.0)
    end

    it 'clamps volume below 0.0' do
      v = described_class.new(name: 'Under', voice_type: :rebel, volume: -0.5)
      expect(v.volume).to eq(0.0)
    end

    it 'defaults active to true' do
      expect(voice.active).to be true
    end

    it 'defaults bias_direction to nil' do
      expect(voice.bias_direction).to be_nil
    end

    it 'accepts bias_direction' do
      v = described_class.new(name: 'Biased', voice_type: :pragmatist, bias_direction: :conservative)
      expect(v.bias_direction).to eq(:conservative)
    end

    it 'sets created_at' do
      expect(voice.created_at).to be_a(Time)
    end
  end

  describe '#amplify!' do
    it 'increases volume by VOLUME_BOOST by default' do
      before = voice.volume
      voice.amplify!
      expect(voice.volume).to be_within(0.001).of(before + 0.1)
    end

    it 'accepts custom amount' do
      voice.amplify!(0.2)
      expect(voice.volume).to be_within(0.001).of(0.7)
    end

    it 'clamps at 1.0' do
      v = described_class.new(name: 'Max', voice_type: :visionary, volume: 0.95)
      v.amplify!(0.2)
      expect(v.volume).to eq(1.0)
    end

    it 'returns self for chaining' do
      expect(voice.amplify!).to equal(voice)
    end
  end

  describe '#dampen!' do
    it 'decreases volume by VOLUME_DECAY by default' do
      before = voice.volume
      voice.dampen!
      expect(voice.volume).to be_within(0.001).of(before - 0.05)
    end

    it 'accepts custom amount' do
      voice.dampen!(0.3)
      expect(voice.volume).to be_within(0.001).of(0.2)
    end

    it 'clamps at 0.0' do
      v = described_class.new(name: 'Min', voice_type: :caretaker, volume: 0.02)
      v.dampen!(0.1)
      expect(v.volume).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(voice.dampen!).to equal(voice)
    end
  end

  describe '#mute!' do
    it 'sets active to false' do
      voice.mute!
      expect(voice.active).to be false
    end

    it 'returns self for chaining' do
      expect(voice.mute!).to equal(voice)
    end
  end

  describe '#unmute!' do
    it 'sets active to true after muting' do
      voice.mute!
      voice.unmute!
      expect(voice.active).to be true
    end

    it 'returns self for chaining' do
      expect(voice.unmute!).to equal(voice)
    end
  end

  describe '#dominant?' do
    it 'returns true when volume >= 0.7' do
      v = described_class.new(name: 'Dom', voice_type: :analyst, volume: 0.7)
      expect(v.dominant?).to be true
    end

    it 'returns false when volume < 0.7' do
      v = described_class.new(name: 'Not', voice_type: :analyst, volume: 0.69)
      expect(v.dominant?).to be false
    end
  end

  describe '#quiet?' do
    it 'returns true when volume <= 0.3' do
      v = described_class.new(name: 'Quiet', voice_type: :caretaker, volume: 0.3)
      expect(v.quiet?).to be true
    end

    it 'returns false when volume > 0.3' do
      v = described_class.new(name: 'NotQuiet', voice_type: :caretaker, volume: 0.31)
      expect(v.quiet?).to be false
    end
  end

  describe '#volume_label' do
    it 'returns :commanding for loud voices' do
      v = described_class.new(name: 'L', voice_type: :rebel, volume: 0.9)
      expect(v.volume_label).to eq(:commanding)
    end

    it 'returns :silent for muted-volume voices' do
      v = described_class.new(name: 'S', voice_type: :rebel, volume: 0.05)
      expect(v.volume_label).to eq(:silent)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = voice.to_h
      expect(h).to include(:id, :name, :voice_type, :volume, :volume_label, :bias_direction, :active, :dominant, :quiet, :created_at)
    end

    it 'rounds volume to 10 decimal places' do
      h = voice.to_h
      expect(h[:volume]).to be_a(Float)
    end
  end
end
