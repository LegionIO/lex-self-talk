# frozen_string_literal: true

module Legion
  module Extensions
    module SelfTalk
      module Helpers
        module LlmEnhancer
          SYSTEM_PROMPT = <<~PROMPT
            You are an internal cognitive voice in an autonomous AI agent's inner dialogue system.
            When asked to speak as a specific voice type, adopt that perspective fully:
            - critic: skeptical, identifies flaws and risks
            - encourager: supportive, finds reasons for optimism
            - analyst: data-driven, logical, weighs evidence
            - devils_advocate: challenges assumptions, plays the contrarian
            - pragmatist: focuses on what's actionable and achievable
            - visionary: thinks big picture, sees future possibilities
            - caretaker: concerned about wellbeing and sustainability
            - rebel: questions authority, pushes for unconventional approaches
            Be concise (1-3 sentences). Stay in character. Take a clear position.
          PROMPT

          module_function

          def available?
            !!(defined?(Legion::LLM) && Legion::LLM.respond_to?(:started?) && Legion::LLM.started?)
          rescue StandardError
            false
          end

          def generate_turn(voice_type:, topic:, prior_turns:)
            prompt = build_generate_turn_prompt(voice_type: voice_type, topic: topic, prior_turns: prior_turns)
            response = llm_ask(prompt)
            parse_generate_turn_response(response)
          rescue StandardError => e
            Legion::Logging.warn "[self_talk:llm] generate_turn failed: #{e.message}"
            nil
          end

          def summarize_dialogue(topic:, turns:)
            prompt = build_summarize_dialogue_prompt(topic: topic, turns: turns)
            response = llm_ask(prompt)
            parse_summarize_dialogue_response(response)
          rescue StandardError => e
            Legion::Logging.warn "[self_talk:llm] summarize_dialogue failed: #{e.message}"
            nil
          end

          # --- Private helpers ---

          def llm_ask(prompt)
            chat = Legion::LLM.chat
            chat.with_instructions(SYSTEM_PROMPT)
            chat.ask(prompt)
          end
          private_class_method :llm_ask

          def build_generate_turn_prompt(voice_type:, topic:, prior_turns:)
            prior_lines = prior_turns.map do |t|
              "[#{t[:voice_name] || t[:voice_id]}] (#{t[:position]}): #{t[:content]}"
            end.join("\n")

            prior_section = prior_lines.empty? ? '(no prior turns)' : prior_lines

            <<~PROMPT
              Topic: #{topic}
              You are speaking as: #{voice_type}

              Previous turns in this dialogue:
              #{prior_section}

              Respond in character. Format EXACTLY as:
              POSITION: support | oppose | question | clarify
              CONTENT: <your 1-3 sentence response>
            PROMPT
          end
          private_class_method :build_generate_turn_prompt

          def parse_generate_turn_response(response)
            return nil unless response&.content

            text = response.content
            position_match = text.match(/POSITION:\s*(support|oppose|question|clarify)/i)
            content_match  = text.match(/CONTENT:\s*(.+)/im)

            return nil unless position_match && content_match

            position = position_match.captures.first.strip.downcase.to_sym
            content  = content_match.captures.first.strip

            { content: content, position: position }
          end
          private_class_method :parse_generate_turn_response

          def build_summarize_dialogue_prompt(topic:, turns:)
            turn_lines = turns.map do |t|
              "[#{t[:voice_name] || t[:voice_id]}] (#{t[:position]}): #{t[:content]}"
            end.join("\n")

            <<~PROMPT
              Topic: #{topic}

              Dialogue turns:
              #{turn_lines}

              Synthesize this dialogue into a conclusion. Format EXACTLY as:
              RECOMMENDATION: support | oppose | abstain
              SUMMARY: <2-3 sentence synthesis of the key points and conclusion>
            PROMPT
          end
          private_class_method :build_summarize_dialogue_prompt

          def parse_summarize_dialogue_response(response)
            return nil unless response&.content

            text = response.content
            recommendation_match = text.match(/RECOMMENDATION:\s*(support|oppose|abstain)/i)
            summary_match        = text.match(/SUMMARY:\s*(.+)/im)

            return nil unless recommendation_match && summary_match

            recommendation = recommendation_match.captures.first.strip.downcase.to_sym
            summary        = summary_match.captures.first.strip

            { summary: summary, recommendation: recommendation }
          end
          private_class_method :parse_summarize_dialogue_response
        end
      end
    end
  end
end
