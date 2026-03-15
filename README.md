# lex-self-talk

Inner dialogue system for brain-modeled agentic AI. Multiple cognitive voices (critic, encourager, analyst, devil's advocate, pragmatist, visionary, caretaker, rebel) engage in structured internal conversations to reason through decisions.

## Overview

`lex-self-talk` implements Vygotsky's inner speech theory and the Internal Family Systems model as a structured deliberation engine. Each voice has a volume (0..1), a type, and an optional bias direction. Voices contribute turns to dialogues, taking positions (support, oppose, question, clarify) with a strength score. The engine tracks consensus across voices and can conclude, deadlock, or abandon dialogues.

## Voice Types

| Type | Role |
|------|------|
| `critic` | Identifies flaws and risks |
| `encourager` | Affirms and motivates |
| `analyst` | Evaluates evidence and logic |
| `devils_advocate` | Challenges assumptions |
| `pragmatist` | Focuses on feasibility |
| `visionary` | Explores possibilities |
| `caretaker` | Considers impact on others |
| `rebel` | Questions constraints |

## Key Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MAX_VOICES` | 10 | Maximum registered voices |
| `MAX_DIALOGUES` | 200 | Maximum stored dialogues (oldest pruned) |
| `MAX_TURNS_PER_DIALOGUE` | 50 | Turn limit per dialogue |
| `DEFAULT_VOLUME` | 0.5 | Starting voice volume |
| `VOLUME_BOOST` | 0.1 | Default amplify amount |
| `VOLUME_DECAY` | 0.05 | Default dampen amount |

## Installation

Add to your Gemfile:

```ruby
gem 'lex-self-talk'
```

## Usage

```ruby
require 'legion/extensions/self_talk'

client = Legion::Extensions::SelfTalk::Client.new

# Register voices
critic_id = client.register_voice(name: 'Inner Critic', voice_type: :critic)[:voice][:id]
analyst_id = client.register_voice(name: 'Analyst', voice_type: :analyst)[:voice][:id]

# Start a dialogue
dialogue_id = client.start_dialogue(topic: 'Should we refactor the auth module?')[:dialogue][:id]

# Voices contribute turns
client.add_turn(dialogue_id: dialogue_id, voice_id: critic_id,
                content: 'The current implementation has hidden coupling', position: :oppose, strength: 0.8)
client.add_turn(dialogue_id: dialogue_id, voice_id: analyst_id,
                content: 'Refactoring now reduces long-term maintenance cost', position: :support, strength: 0.7)

# Get a report
report = client.dialogue_report(dialogue_id: dialogue_id)
# => { found: true, dialogue: {...}, voice_positions: { "Inner Critic" => 0.8, "Analyst" => 0.7 } }

# Conclude the dialogue
client.conclude_dialogue(dialogue_id: dialogue_id, summary: 'Refactor in next sprint')

# Check status
client.self_talk_status
# => { voice_count: 2, dialogue_count: 1, active_dialogue_count: 0, ... }
```

## Dominance Labels

| Volume Range | Label |
|-------------|-------|
| 0.8 - 1.0 | `:commanding` |
| 0.6 - 0.8 | `:assertive` |
| 0.4 - 0.6 | `:balanced` |
| 0.2 - 0.4 | `:quiet` |
| 0.0 - 0.2 | `:silent` |

## Consensus Labels

| Score Range | Label |
|------------|-------|
| 0.8 - 1.0 | `:unanimous` |
| 0.6 - 0.8 | `:agreement` |
| 0.4 - 0.6 | `:mixed` |
| 0.2 - 0.4 | `:disagreement` |
| 0.0 - 0.2 | `:conflict` |

## Actors

| Actor | Interval | Description |
|-------|----------|-------------|
| `VolumeDecay` | Every 300s | Calls `dampen!` on every active voice by `VOLUME_DECAY` (0.05), preventing voices from holding elevated volumes indefinitely. Voices that are never amplified will trend toward silence over time. Muted voices are skipped. |

## LLM Enhancement

`Helpers::LlmEnhancer` provides optional LLM-powered voice generation and dialogue summarization when `legion-llm` is loaded and `Legion::LLM.started?` returns true. All methods rescue `StandardError` and return `nil` — callers always fall back to mechanical processing.

| Method | Description |
|--------|-------------|
| `generate_turn(voice_type:, topic:, prior_turns:)` | Generates a realistic in-character 1-3 sentence response for the given voice type, returning a `position` (`:support`, `:oppose`, `:question`, or `:clarify`) and `content` |
| `summarize_dialogue(topic:, turns:)` | Synthesizes all dialogue turns into a 2-3 sentence conclusion with a `recommendation` (`:support`, `:oppose`, or `:abstain`) and a `summary` |

Mechanical fallback: `generate_voice_turn` uses the stub string `"[voice_type perspective on topic]"` with position `:clarify` when LLM is unavailable or returns `nil`. `conclude_dialogue` uses `"Dialogue concluded"` as the summary. The `source:` field in `generate_voice_turn` results is `:llm` or `:mechanical` to indicate which path was taken.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
