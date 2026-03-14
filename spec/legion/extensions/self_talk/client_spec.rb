# frozen_string_literal: true

require 'legion/extensions/self_talk/client'

RSpec.describe Legion::Extensions::SelfTalk::Client do
  let(:client) { described_class.new }

  it 'responds to runner methods' do
    expect(client).to respond_to(:register_voice)
    expect(client).to respond_to(:start_dialogue)
    expect(client).to respond_to(:add_turn)
    expect(client).to respond_to(:conclude_dialogue)
    expect(client).to respond_to(:deadlock_dialogue)
    expect(client).to respond_to(:amplify_voice)
    expect(client).to respond_to(:dampen_voice)
    expect(client).to respond_to(:dialogue_report)
    expect(client).to respond_to(:self_talk_status)
  end

  it 'each instance has independent state' do
    c1 = described_class.new
    c2 = described_class.new
    c1.register_voice(name: 'Lone Voice', voice_type: :critic)
    expect(c2.self_talk_status[:voice_count]).to eq(0)
  end
end
