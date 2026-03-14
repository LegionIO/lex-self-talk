# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module SelfTalk
      module Helpers
        class InnerVoice
          attr_reader :id, :name, :voice_type, :bias_direction, :created_at
          attr_accessor :volume, :active

          def initialize(name:, voice_type:, volume: Constants::DEFAULT_VOLUME, bias_direction: nil, active: true)
            @id             = SecureRandom.uuid
            @name           = name
            @voice_type     = voice_type
            @volume         = volume.clamp(0.0, 1.0)
            @bias_direction = bias_direction
            @active         = active
            @created_at     = Time.now.utc
          end

          def amplify!(amount = Constants::VOLUME_BOOST)
            @volume = (@volume + amount).clamp(0.0, 1.0)
            self
          end

          def dampen!(amount = Constants::VOLUME_DECAY)
            @volume = (@volume - amount).clamp(0.0, 1.0)
            self
          end

          def mute!
            @active = false
            self
          end

          def unmute!
            @active = true
            self
          end

          def dominant?
            @volume >= 0.7
          end

          def quiet?
            @volume <= 0.3
          end

          def volume_label
            Constants.dominance_label(@volume)
          end

          def to_h
            {
              id:             @id,
              name:           @name,
              voice_type:     @voice_type,
              volume:         @volume.round(10),
              volume_label:   volume_label,
              bias_direction: @bias_direction,
              active:         @active,
              dominant:       dominant?,
              quiet:          quiet?,
              created_at:     @created_at
            }
          end
        end
      end
    end
  end
end
