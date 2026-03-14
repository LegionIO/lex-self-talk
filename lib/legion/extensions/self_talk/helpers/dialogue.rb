# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module SelfTalk
      module Helpers
        class Dialogue
          attr_reader :id, :topic, :turns, :status, :conclusion, :created_at

          def initialize(topic:)
            @id         = SecureRandom.uuid
            @topic      = topic
            @turns      = []
            @status     = :open
            @conclusion = nil
            @created_at = Time.now.utc
          end

          def add_turn!(voice_id:, content:, position: :clarify, strength: 0.5)
            return false if @turns.size >= Constants::MAX_TURNS_PER_DIALOGUE
            return false unless active?

            turn = DialogueTurn.new(
              dialogue_id: @id,
              voice_id:    voice_id,
              content:     content,
              position:    position,
              strength:    strength
            )
            @turns << turn
            turn
          end

          def conclude!(summary)
            return false unless active?

            @conclusion = summary
            @status     = :concluded
            true
          end

          def deadlock!
            return false unless active?

            @status = :deadlocked
            true
          end

          def abandon!
            return false unless active?

            @status = :abandoned
            true
          end

          def active?
            @status == :open
          end

          def concluded?
            @status == :concluded
          end

          def turn_count
            @turns.size
          end

          def voice_positions
            grouped = @turns.group_by(&:voice_id)
            grouped.transform_values do |voice_turns|
              voice_turns.sum(&:strength) / voice_turns.size.to_f
            end
          end

          def consensus_score
            return 1.0 if @turns.empty?

            support_strength = @turns.select { |t| t.position == :support }.sum(&:strength)
            oppose_strength  = @turns.select { |t| t.position == :oppose }.sum(&:strength)
            total            = support_strength + oppose_strength
            return 0.5 if total.zero?

            stronger = [support_strength, oppose_strength].max
            stronger / total
          end

          def consensus_label
            Constants.consensus_label(consensus_score)
          end

          def to_h
            {
              id:              @id,
              topic:           @topic,
              status:          @status,
              conclusion:      @conclusion,
              turn_count:      turn_count,
              consensus_score: consensus_score.round(10),
              consensus_label: consensus_label,
              created_at:      @created_at,
              turns:           @turns.map(&:to_h)
            }
          end
        end
      end
    end
  end
end
