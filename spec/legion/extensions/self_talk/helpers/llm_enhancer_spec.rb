# frozen_string_literal: true

RSpec.describe Legion::Extensions::SelfTalk::Helpers::LlmEnhancer do
  describe '.available?' do
    context 'when Legion::LLM is not defined' do
      it 'returns false' do
        hide_const('Legion::LLM')
        expect(described_class.available?).to be false
      end
    end

    context 'when Legion::LLM is defined but not started' do
      it 'returns false' do
        llm_double = double('Legion::LLM', started?: false)
        stub_const('Legion::LLM', llm_double)
        expect(described_class.available?).to be false
      end
    end

    context 'when Legion::LLM is started' do
      it 'returns true' do
        llm_double = double('Legion::LLM', started?: true)
        stub_const('Legion::LLM', llm_double)
        expect(described_class.available?).to be true
      end
    end

    context 'when Legion::LLM raises an error' do
      it 'returns false' do
        llm_double = double('Legion::LLM')
        allow(llm_double).to receive(:respond_to?).and_raise(StandardError)
        stub_const('Legion::LLM', llm_double)
        expect(described_class.available?).to be false
      end
    end
  end

  describe '.generate_turn' do
    let(:prior_turns) do
      [
        { voice_name: 'Analyst', voice_id: 'uuid-1', position: :support,  content: 'The data supports this.' },
        { voice_name: 'Critic',  voice_id: 'uuid-2', position: :oppose,   content: 'There are serious risks.' }
      ]
    end

    context 'when LLM returns a valid formatted response' do
      it 'returns content and position hash' do
        response_double = double('response', content: "POSITION: oppose\nCONTENT: The risks outweigh the benefits here.")
        chat_double = double('chat')
        allow(chat_double).to receive(:with_instructions)
        allow(chat_double).to receive(:ask).and_return(response_double)
        llm_double = double('Legion::LLM', started?: true)
        allow(llm_double).to receive(:chat).and_return(chat_double)
        stub_const('Legion::LLM', llm_double)

        result = described_class.generate_turn(
          voice_type:  :critic,
          topic:       'Should we proceed with the plan?',
          prior_turns: prior_turns
        )

        expect(result).to be_a(Hash)
        expect(result[:content]).to eq('The risks outweigh the benefits here.')
        expect(result[:position]).to eq(:oppose)
      end
    end

    context 'when LLM returns a support position' do
      it 'parses support correctly' do
        response_double = double('response', content: "POSITION: support\nCONTENT: I think we should go forward.")
        chat_double = double('chat')
        allow(chat_double).to receive(:with_instructions)
        allow(chat_double).to receive(:ask).and_return(response_double)
        llm_double = double('Legion::LLM', started?: true)
        allow(llm_double).to receive(:chat).and_return(chat_double)
        stub_const('Legion::LLM', llm_double)

        result = described_class.generate_turn(
          voice_type:  :encourager,
          topic:       'Should we proceed?',
          prior_turns: []
        )

        expect(result[:position]).to eq(:support)
      end
    end

    context 'when LLM returns unparseable response' do
      it 'returns nil' do
        response_double = double('response', content: 'This is not formatted correctly.')
        chat_double = double('chat')
        allow(chat_double).to receive(:with_instructions)
        allow(chat_double).to receive(:ask).and_return(response_double)
        llm_double = double('Legion::LLM', started?: true)
        allow(llm_double).to receive(:chat).and_return(chat_double)
        stub_const('Legion::LLM', llm_double)

        result = described_class.generate_turn(
          voice_type:  :analyst,
          topic:       'test',
          prior_turns: []
        )

        expect(result).to be_nil
      end
    end

    context 'when LLM returns nil' do
      it 'returns nil' do
        chat_double = double('chat')
        allow(chat_double).to receive(:with_instructions)
        allow(chat_double).to receive(:ask).and_return(nil)
        llm_double = double('Legion::LLM', started?: true)
        allow(llm_double).to receive(:chat).and_return(chat_double)
        stub_const('Legion::LLM', llm_double)

        result = described_class.generate_turn(voice_type: :analyst, topic: 'test', prior_turns: [])
        expect(result).to be_nil
      end
    end

    context 'when an error occurs' do
      it 'returns nil and logs a warning' do
        llm_double = double('Legion::LLM', started?: true)
        allow(llm_double).to receive(:chat).and_raise(StandardError, 'timeout')
        stub_const('Legion::LLM', llm_double)

        expect(Legion::Logging).to receive(:warn).with(/self_talk:llm.*generate_turn failed/)
        result = described_class.generate_turn(voice_type: :critic, topic: 'test', prior_turns: [])
        expect(result).to be_nil
      end
    end
  end

  describe '.summarize_dialogue' do
    let(:turns) do
      [
        { voice_name: 'Analyst', voice_id: 'uuid-1', position: :support,  content: 'Evidence is strong.' },
        { voice_name: 'Critic',  voice_id: 'uuid-2', position: :oppose,   content: 'Too risky.' },
        { voice_name: 'Pragmatist', voice_id: 'uuid-3', position: :clarify, content: 'Let us scope this down.' }
      ]
    end

    context 'when LLM returns a valid formatted response' do
      it 'returns summary and recommendation hash' do
        response_double = double('response',
                                 content: "RECOMMENDATION: abstain\nSUMMARY: The dialogue was split. A smaller scope was suggested.")
        chat_double = double('chat')
        allow(chat_double).to receive(:with_instructions)
        allow(chat_double).to receive(:ask).and_return(response_double)
        llm_double = double('Legion::LLM', started?: true)
        allow(llm_double).to receive(:chat).and_return(chat_double)
        stub_const('Legion::LLM', llm_double)

        result = described_class.summarize_dialogue(topic: 'Should we proceed?', turns: turns)

        expect(result).to be_a(Hash)
        expect(result[:recommendation]).to eq(:abstain)
        expect(result[:summary]).to include('smaller scope')
      end
    end

    context 'when LLM returns a support recommendation' do
      it 'parses support correctly' do
        response_double = double('response',
                                 content: "RECOMMENDATION: support\nSUMMARY: The group agreed to move forward.")
        chat_double = double('chat')
        allow(chat_double).to receive(:with_instructions)
        allow(chat_double).to receive(:ask).and_return(response_double)
        llm_double = double('Legion::LLM', started?: true)
        allow(llm_double).to receive(:chat).and_return(chat_double)
        stub_const('Legion::LLM', llm_double)

        result = described_class.summarize_dialogue(topic: 'test', turns: [])
        expect(result[:recommendation]).to eq(:support)
      end
    end

    context 'when LLM returns unparseable response' do
      it 'returns nil' do
        response_double = double('response', content: 'No clear structure here.')
        chat_double = double('chat')
        allow(chat_double).to receive(:with_instructions)
        allow(chat_double).to receive(:ask).and_return(response_double)
        llm_double = double('Legion::LLM', started?: true)
        allow(llm_double).to receive(:chat).and_return(chat_double)
        stub_const('Legion::LLM', llm_double)

        result = described_class.summarize_dialogue(topic: 'test', turns: [])
        expect(result).to be_nil
      end
    end

    context 'when an error occurs' do
      it 'returns nil and logs a warning' do
        llm_double = double('Legion::LLM', started?: true)
        allow(llm_double).to receive(:chat).and_raise(StandardError, 'network error')
        stub_const('Legion::LLM', llm_double)

        expect(Legion::Logging).to receive(:warn).with(/self_talk:llm.*summarize_dialogue failed/)
        result = described_class.summarize_dialogue(topic: 'test', turns: [])
        expect(result).to be_nil
      end
    end
  end
end
