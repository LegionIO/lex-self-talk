# frozen_string_literal: true

module Legion
  module Extensions
    module SelfTalk
      module Helpers
        class SelfTalkEngine
          attr_reader :voices, :dialogues

          def initialize
            @voices    = {}
            @dialogues = {}
          end

          def register_voice(name:, voice_type:, volume: Constants::DEFAULT_VOLUME, bias_direction: nil)
            return { registered: false, reason: :max_voices } if @voices.size >= Constants::MAX_VOICES
            return { registered: false, reason: :unknown_type } unless Constants::VOICE_TYPES.include?(voice_type)

            voice = InnerVoice.new(
              name:           name,
              voice_type:     voice_type,
              volume:         volume,
              bias_direction: bias_direction
            )
            @voices[voice.id] = voice
            { registered: true, voice: voice.to_h }
          end

          def start_dialogue(topic:)
            prune_dialogues_if_needed
            dialogue = Dialogue.new(topic: topic)
            @dialogues[dialogue.id] = dialogue
            { started: true, dialogue: dialogue.to_h }
          end

          def add_turn(dialogue_id:, voice_id:, content:, position: :clarify, strength: 0.5)
            dialogue = @dialogues[dialogue_id]
            return { added: false, reason: :dialogue_not_found } unless dialogue

            voice = @voices[voice_id]
            return { added: false, reason: :voice_not_found } unless voice
            return { added: false, reason: :voice_inactive } unless voice.active

            turn = dialogue.add_turn!(
              voice_id: voice_id,
              content:  content,
              position: position,
              strength: strength
            )
            return { added: false, reason: :limit_reached_or_closed } unless turn

            { added: true, turn: turn.to_h }
          end

          def conclude_dialogue(dialogue_id:, summary:)
            dialogue = @dialogues[dialogue_id]
            return { concluded: false, reason: :not_found } unless dialogue

            result = dialogue.conclude!(summary)
            { concluded: result, dialogue_id: dialogue_id }
          end

          def deadlock_dialogue(dialogue_id:)
            dialogue = @dialogues[dialogue_id]
            return { deadlocked: false, reason: :not_found } unless dialogue

            result = dialogue.deadlock!
            { deadlocked: result, dialogue_id: dialogue_id }
          end

          def active_dialogues
            @dialogues.values.select(&:active?)
          end

          def concluded_dialogues
            @dialogues.values.select(&:concluded?)
          end

          def dominant_voice
            active = @voices.values.select(&:active)
            return nil if active.empty?

            active.max_by(&:volume)
          end

          def quietest_voice
            active = @voices.values.select(&:active)
            return nil if active.empty?

            active.min_by(&:volume)
          end

          def voice_balance
            return {} if @voices.empty?

            total = @voices.values.sum(&:volume)
            @voices.transform_values do |v|
              total.positive? ? (v.volume / total).round(10) : 0.0
            end
          end

          def amplify_voice(voice_id:, amount: Constants::VOLUME_BOOST)
            voice = @voices[voice_id]
            return { amplified: false, reason: :not_found } unless voice

            voice.amplify!(amount)
            { amplified: true, voice_id: voice_id, volume: voice.volume.round(10) }
          end

          def dampen_voice(voice_id:, amount: Constants::VOLUME_DECAY)
            voice = @voices[voice_id]
            return { dampened: false, reason: :not_found } unless voice

            voice.dampen!(amount)
            { dampened: true, voice_id: voice_id, volume: voice.volume.round(10) }
          end

          def dialogue_report(dialogue_id:)
            dialogue = @dialogues[dialogue_id]
            return { found: false } unless dialogue

            positions = dialogue.voice_positions.transform_keys do |vid|
              @voices[vid]&.name || vid
            end

            {
              found:           true,
              dialogue:        dialogue.to_h,
              voice_positions: positions
            }
          end

          def to_h
            {
              voice_count:           @voices.size,
              dialogue_count:        @dialogues.size,
              active_dialogue_count: active_dialogues.size,
              dominant_voice:        dominant_voice&.to_h,
              quietest_voice:        quietest_voice&.to_h,
              voice_balance:         voice_balance
            }
          end

          private

          def prune_dialogues_if_needed
            return unless @dialogues.size >= Constants::MAX_DIALOGUES

            oldest_key = @dialogues.min_by { |_, d| d.created_at }&.first
            @dialogues.delete(oldest_key) if oldest_key
          end
        end
      end
    end
  end
end
