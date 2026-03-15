# frozen_string_literal: true

module Legion
  module Extensions
    module SelfTalk
      module Runners
        module SelfTalk
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def register_voice(name:, voice_type:, volume: Helpers::Constants::DEFAULT_VOLUME,
                             bias_direction: nil, **)
            result = engine.register_voice(
              name:           name,
              voice_type:     voice_type,
              volume:         volume,
              bias_direction: bias_direction
            )
            Legion::Logging.info "[self_talk] register_voice: name=#{name} type=#{voice_type} registered=#{result[:registered]}"
            result
          end

          def start_dialogue(topic:, **)
            result = engine.start_dialogue(topic: topic)
            Legion::Logging.debug "[self_talk] start_dialogue: topic=#{topic} id=#{result[:dialogue][:id]}"
            result
          end

          def add_turn(dialogue_id:, voice_id:, content:, position: :clarify, strength: 0.5, **)
            result = engine.add_turn(
              dialogue_id: dialogue_id,
              voice_id:    voice_id,
              content:     content,
              position:    position,
              strength:    strength
            )
            Legion::Logging.debug "[self_talk] add_turn: dialogue=#{dialogue_id} voice=#{voice_id} added=#{result[:added]}"
            result
          end

          def conclude_dialogue(dialogue_id:, summary: nil, **)
            resolved_summary = summary || generate_summary_for_dialogue(dialogue_id)
            result = engine.conclude_dialogue(dialogue_id: dialogue_id, summary: resolved_summary)
            Legion::Logging.info "[self_talk] conclude_dialogue: id=#{dialogue_id} concluded=#{result[:concluded]}"
            result
          end

          def generate_voice_turn(dialogue_id:, voice_id:, **)
            dialogue_data = engine.dialogues[dialogue_id]
            voice_data    = engine.voices[voice_id]
            return missing_entity_error(dialogue_data) unless dialogue_data && voice_data

            content, source = resolve_turn_content(voice_data, dialogue_data)
            turn_result = add_turn(
              dialogue_id: dialogue_id,
              voice_id:    voice_id,
              content:     content[:content],
              position:    content[:position]
            )
            Legion::Logging.debug "[self_talk] generate_voice_turn: dialogue=#{dialogue_id} voice=#{voice_id} source=#{source}"
            { generated: true, source: source, turn: turn_result[:turn] }
          end

          def deadlock_dialogue(dialogue_id:, **)
            result = engine.deadlock_dialogue(dialogue_id: dialogue_id)
            Legion::Logging.warn "[self_talk] deadlock_dialogue: id=#{dialogue_id} deadlocked=#{result[:deadlocked]}"
            result
          end

          def amplify_voice(voice_id:, amount: Helpers::Constants::VOLUME_BOOST, **)
            result = engine.amplify_voice(voice_id: voice_id, amount: amount)
            Legion::Logging.debug "[self_talk] amplify_voice: id=#{voice_id} volume=#{result[:volume]}"
            result
          end

          def dampen_voice(voice_id:, amount: Helpers::Constants::VOLUME_DECAY, **)
            result = engine.dampen_voice(voice_id: voice_id, amount: amount)
            Legion::Logging.debug "[self_talk] dampen_voice: id=#{voice_id} volume=#{result[:volume]}"
            result
          end

          def dialogue_report(dialogue_id:, **)
            result = engine.dialogue_report(dialogue_id: dialogue_id)
            Legion::Logging.debug "[self_talk] dialogue_report: id=#{dialogue_id} found=#{result[:found]}"
            result
          end

          def self_talk_status(**)
            summary = engine.to_h
            Legion::Logging.debug "[self_talk] status: voices=#{summary[:voice_count]} dialogues=#{summary[:dialogue_count]}"
            summary
          end

          def decay_voices(**)
            decayed = 0
            voice_list = engine.voices.values.select(&:active).map do |voice|
              voice.dampen!(Helpers::Constants::VOLUME_DECAY)
              decayed += 1
              { id: voice.id, name: voice.name, volume: voice.volume }
            end
            Legion::Logging.debug "[self-talk] voice decay: decayed=#{decayed} voices"
            { decayed: decayed, voices: voice_list }
          end

          private

          def engine
            @engine ||= Helpers::SelfTalkEngine.new
          end

          def missing_entity_error(dialogue_data)
            { generated: false, reason: dialogue_data ? :voice_not_found : :dialogue_not_found }
          end

          def resolve_turn_content(voice_data, dialogue_data)
            prior_turns = build_prior_turns(dialogue_data)
            if Helpers::LlmEnhancer.available?
              llm_result = Helpers::LlmEnhancer.generate_turn(
                voice_type:  voice_data.voice_type,
                topic:       dialogue_data.topic,
                prior_turns: prior_turns
              )
              return [llm_result, :llm] if llm_result
            end
            [stub_turn_content(voice_data.voice_type, dialogue_data.topic), :mechanical]
          end

          def build_prior_turns(dialogue_data)
            dialogue_data.turns.map do |t|
              speaking_voice = engine.voices[t.voice_id]
              { voice_id: t.voice_id, voice_name: speaking_voice&.name || t.voice_id,
                position: t.position, content: t.content }
            end
          end

          def stub_turn_content(voice_type, topic)
            { content: "[#{voice_type} perspective on #{topic}]", position: :clarify }
          end

          def generate_summary_for_dialogue(dialogue_id)
            dialogue_data = engine.dialogues[dialogue_id]
            return 'Dialogue concluded' unless dialogue_data

            if Helpers::LlmEnhancer.available?
              turns = dialogue_data.turns.map do |t|
                speaking_voice = engine.voices[t.voice_id]
                {
                  voice_id:   t.voice_id,
                  voice_name: speaking_voice&.name || t.voice_id,
                  position:   t.position,
                  content:    t.content
                }
              end

              llm_result = Helpers::LlmEnhancer.summarize_dialogue(
                topic: dialogue_data.topic,
                turns: turns
              )
              return llm_result[:summary] if llm_result
            end

            'Dialogue concluded'
          end
        end
      end
    end
  end
end
