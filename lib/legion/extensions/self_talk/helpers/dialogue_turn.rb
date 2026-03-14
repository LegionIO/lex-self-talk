# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module SelfTalk
      module Helpers
        class DialogueTurn
          POSITIONS = %i[support oppose question clarify].freeze

          attr_reader :id, :dialogue_id, :voice_id, :content, :position, :strength, :created_at

          def initialize(dialogue_id:, voice_id:, content:, position: :clarify, strength: 0.5)
            @id          = SecureRandom.uuid
            @dialogue_id = dialogue_id
            @voice_id    = voice_id
            @content     = content
            @position    = POSITIONS.include?(position) ? position : :clarify
            @strength    = strength.clamp(0.0, 1.0)
            @created_at  = Time.now.utc
          end

          def to_h
            {
              id:          @id,
              dialogue_id: @dialogue_id,
              voice_id:    @voice_id,
              content:     @content,
              position:    @position,
              strength:    @strength.round(10),
              created_at:  @created_at
            }
          end
        end
      end
    end
  end
end
