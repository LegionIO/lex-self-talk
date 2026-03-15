# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module SelfTalk
      module Actor
        class VolumeDecay < Legion::Extensions::Actors::Every
          def runner_class
            Legion::Extensions::SelfTalk::Runners::SelfTalk
          end

          def runner_function
            'decay_voices'
          end

          def time
            300
          end

          def run_now?
            false
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
