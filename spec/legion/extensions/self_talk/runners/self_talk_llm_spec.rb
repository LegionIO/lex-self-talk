# frozen_string_literal: true

require 'legion/extensions/self_talk/client'

RSpec.describe Legion::Extensions::SelfTalk::Runners::SelfTalk, 'LLM integration' do
  let(:client) { Legion::Extensions::SelfTalk::Client.new }

  def register_voice(name: 'Analyst', type: :analyst)
    result = client.register_voice(name: name, voice_type: type)
    result[:voice][:id]
  end

  def start_dialogue(topic: 'Shall we proceed?')
    result = client.start_dialogue(topic: topic)
    result[:dialogue][:id]
  end

  describe '#generate_voice_turn' do
    context 'when LLM is available and returns a valid turn' do
      before do
        llm_result = { content: 'The evidence strongly supports this decision.', position: :support }
        allow(Legion::Extensions::SelfTalk::Helpers::LlmEnhancer).to receive(:available?).and_return(true)
        allow(Legion::Extensions::SelfTalk::Helpers::LlmEnhancer).to receive(:generate_turn).and_return(llm_result)
      end

      it 'returns generated: true with source: :llm' do
        vid = register_voice
        did = start_dialogue
        result = client.generate_voice_turn(dialogue_id: did, voice_id: vid)
        expect(result[:generated]).to be true
        expect(result[:source]).to eq(:llm)
      end

      it 'adds a turn to the dialogue' do
        vid = register_voice
        did = start_dialogue
        client.generate_voice_turn(dialogue_id: did, voice_id: vid)
        report = client.dialogue_report(dialogue_id: did)
        expect(report[:dialogue][:turn_count]).to eq(1)
      end

      it 'includes turn data in result' do
        vid = register_voice
        did = start_dialogue
        result = client.generate_voice_turn(dialogue_id: did, voice_id: vid)
        expect(result[:turn]).to be_a(Hash)
      end
    end

    context 'when LLM is available but returns nil' do
      before do
        allow(Legion::Extensions::SelfTalk::Helpers::LlmEnhancer).to receive(:available?).and_return(true)
        allow(Legion::Extensions::SelfTalk::Helpers::LlmEnhancer).to receive(:generate_turn).and_return(nil)
      end

      it 'falls back to mechanical stub with source: :mechanical' do
        vid = register_voice
        did = start_dialogue
        result = client.generate_voice_turn(dialogue_id: did, voice_id: vid)
        expect(result[:generated]).to be true
        expect(result[:source]).to eq(:mechanical)
      end

      it 'adds a clarify-position turn with stub content' do
        vid = register_voice(name: 'Analyst', type: :analyst)
        did = start_dialogue(topic: 'My topic')
        client.generate_voice_turn(dialogue_id: did, voice_id: vid)
        report = client.dialogue_report(dialogue_id: did)
        expect(report[:dialogue][:turn_count]).to eq(1)
      end
    end

    context 'when LLM is unavailable' do
      before do
        allow(Legion::Extensions::SelfTalk::Helpers::LlmEnhancer).to receive(:available?).and_return(false)
      end

      it 'uses mechanical stub with source: :mechanical' do
        vid = register_voice
        did = start_dialogue(topic: 'Test topic')
        result = client.generate_voice_turn(dialogue_id: did, voice_id: vid)
        expect(result[:generated]).to be true
        expect(result[:source]).to eq(:mechanical)
        expect(result[:turn]).to be_a(Hash)
      end
    end

    context 'when dialogue is not found' do
      it 'returns generated: false with reason' do
        vid = register_voice
        result = client.generate_voice_turn(dialogue_id: 'bad-id', voice_id: vid)
        expect(result[:generated]).to be false
        expect(result[:reason]).to eq(:dialogue_not_found)
      end
    end

    context 'when voice is not found' do
      it 'returns generated: false with reason' do
        did = start_dialogue
        result = client.generate_voice_turn(dialogue_id: did, voice_id: 'bad-voice-id')
        expect(result[:generated]).to be false
        expect(result[:reason]).to eq(:voice_not_found)
      end
    end
  end

  describe '#conclude_dialogue auto-summary' do
    context 'when no summary is provided and LLM is available' do
      before do
        llm_result = { summary: 'The voices reached a tentative agreement.', recommendation: :support }
        allow(Legion::Extensions::SelfTalk::Helpers::LlmEnhancer).to receive(:available?).and_return(true)
        allow(Legion::Extensions::SelfTalk::Helpers::LlmEnhancer).to receive(:summarize_dialogue).and_return(llm_result)
      end

      it 'generates an LLM summary and concludes the dialogue' do
        did = start_dialogue
        result = client.conclude_dialogue(dialogue_id: did)
        expect(result[:concluded]).to be true
      end

      it 'stores the LLM summary as the conclusion' do
        did = start_dialogue
        client.conclude_dialogue(dialogue_id: did)
        report = client.dialogue_report(dialogue_id: did)
        expect(report[:dialogue][:conclusion]).to eq('The voices reached a tentative agreement.')
      end
    end

    context 'when no summary is provided and LLM returns nil' do
      before do
        allow(Legion::Extensions::SelfTalk::Helpers::LlmEnhancer).to receive(:available?).and_return(true)
        allow(Legion::Extensions::SelfTalk::Helpers::LlmEnhancer).to receive(:summarize_dialogue).and_return(nil)
      end

      it 'falls back to mechanical default summary' do
        did = start_dialogue
        result = client.conclude_dialogue(dialogue_id: did)
        expect(result[:concluded]).to be true
        report = client.dialogue_report(dialogue_id: did)
        expect(report[:dialogue][:conclusion]).to eq('Dialogue concluded')
      end
    end

    context 'when no summary is provided and LLM is unavailable' do
      before do
        allow(Legion::Extensions::SelfTalk::Helpers::LlmEnhancer).to receive(:available?).and_return(false)
      end

      it 'uses mechanical default summary' do
        did = start_dialogue
        result = client.conclude_dialogue(dialogue_id: did)
        expect(result[:concluded]).to be true
        report = client.dialogue_report(dialogue_id: did)
        expect(report[:dialogue][:conclusion]).to eq('Dialogue concluded')
      end
    end

    context 'when an explicit summary is provided' do
      it 'uses the provided summary regardless of LLM availability' do
        allow(Legion::Extensions::SelfTalk::Helpers::LlmEnhancer).to receive(:available?).and_return(true)
        did = start_dialogue
        result = client.conclude_dialogue(dialogue_id: did, summary: 'We decided to wait.')
        expect(result[:concluded]).to be true
        report = client.dialogue_report(dialogue_id: did)
        expect(report[:dialogue][:conclusion]).to eq('We decided to wait.')
      end
    end
  end
end
