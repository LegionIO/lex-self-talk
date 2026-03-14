# frozen_string_literal: true

module Legion
  module Extensions
    module SelfTalk
      module Helpers
        module Constants
          MAX_VOICES           = 10
          MAX_DIALOGUES        = 200
          MAX_TURNS_PER_DIALOGUE = 50
          DEFAULT_VOLUME       = 0.5
          VOLUME_BOOST         = 0.1
          VOLUME_DECAY         = 0.05

          VOICE_TYPES = %i[
            critic
            encourager
            analyst
            devils_advocate
            pragmatist
            visionary
            caretaker
            rebel
          ].freeze

          DIALOGUE_STATUSES = %i[open concluded deadlocked abandoned].freeze

          DOMINANCE_LABELS = {
            (0.8..1.0)  => :commanding,
            (0.6...0.8) => :assertive,
            (0.4...0.6) => :balanced,
            (0.2...0.4) => :quiet,
            (0.0...0.2) => :silent
          }.freeze

          CONSENSUS_LABELS = {
            (0.8..1.0)  => :unanimous,
            (0.6...0.8) => :agreement,
            (0.4...0.6) => :mixed,
            (0.2...0.4) => :disagreement,
            (0.0...0.2) => :conflict
          }.freeze

          module_function

          def dominance_label(volume)
            DOMINANCE_LABELS.each { |range, label| return label if range.cover?(volume) }
            :silent
          end

          def consensus_label(score)
            CONSENSUS_LABELS.each { |range, label| return label if range.cover?(score) }
            :conflict
          end
        end
      end
    end
  end
end
