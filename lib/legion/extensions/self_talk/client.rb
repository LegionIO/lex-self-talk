# frozen_string_literal: true

require 'legion/extensions/self_talk/helpers/constants'
require 'legion/extensions/self_talk/helpers/inner_voice'
require 'legion/extensions/self_talk/helpers/dialogue_turn'
require 'legion/extensions/self_talk/helpers/dialogue'
require 'legion/extensions/self_talk/helpers/self_talk_engine'
require 'legion/extensions/self_talk/runners/self_talk'

module Legion
  module Extensions
    module SelfTalk
      class Client
        include Runners::SelfTalk

        def initialize(**)
          @engine = Helpers::SelfTalkEngine.new
        end

        private

        attr_reader :engine
      end
    end
  end
end
