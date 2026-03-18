# lex-self-talk

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Inner dialogue system for the LegionIO cognitive architecture. Implements Vygotsky's inner speech theory and the Internal Family Systems model as a structured deliberation engine. Multiple cognitive voices engage in typed dialogues to reason through decisions before action.

## Gem Info

- **Gem name**: `lex-self-talk`
- **Version**: `0.1.1`
- **Module**: `Legion::Extensions::SelfTalk`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/self_talk/
  version.rb
  helpers/
    constants.rb        # MAX_VOICES, MAX_DIALOGUES, MAX_TURNS_PER_DIALOGUE, VOICE_TYPES,
                        # DIALOGUE_STATUSES, DOMINANCE_LABELS, CONSENSUS_LABELS, label helpers
    inner_voice.rb      # InnerVoice class - id, name, voice_type, volume, bias_direction, active
                        # amplify!, dampen!, mute!, unmute!, dominant?, quiet?, volume_label, to_h
    dialogue_turn.rb    # DialogueTurn class - id, dialogue_id, voice_id, content, position, strength
    dialogue.rb         # Dialogue class - topic, turns, status, conclusion
                        # add_turn!, conclude!, deadlock!, abandon!, consensus_score, voice_positions
    self_talk_engine.rb # SelfTalkEngine class - coordinates voices and dialogues
    llm_enhancer.rb     # LlmEnhancer module - generate_turn, summarize_dialogue
  runners/
    self_talk.rb        # register_voice, start_dialogue, add_turn, conclude_dialogue,
                        # deadlock_dialogue, amplify_voice, dampen_voice, dialogue_report,
                        # self_talk_status, decay_voices, generate_voice_turn
  actors/
    volume_decay.rb     # VolumeDecay - Every 300s, calls decay_voices
spec/
  legion/extensions/self_talk/
    helpers/
      constants_spec.rb
      inner_voice_spec.rb
      dialogue_turn_spec.rb
      dialogue_spec.rb
      self_talk_engine_spec.rb
    runners/
      self_talk_spec.rb
    client_spec.rb
```

## Key Constants (Helpers::Constants)

```ruby
MAX_VOICES             = 10
MAX_DIALOGUES          = 200
MAX_TURNS_PER_DIALOGUE = 50
DEFAULT_VOLUME         = 0.5
VOLUME_BOOST           = 0.1
VOLUME_DECAY           = 0.05

VOICE_TYPES = %i[critic encourager analyst devils_advocate pragmatist visionary caretaker rebel]

DIALOGUE_STATUSES = %i[open concluded deadlocked abandoned]

DOMINANCE_LABELS = {
  (0.8..1.0)  => :commanding,
  (0.6...0.8) => :assertive,
  (0.4...0.6) => :balanced,
  (0.2...0.4) => :quiet,
  (0.0...0.2) => :silent
}

CONSENSUS_LABELS = {
  (0.8..1.0)  => :unanimous,
  (0.6...0.8) => :agreement,
  (0.4...0.6) => :mixed,
  (0.2...0.4) => :disagreement,
  (0.0...0.2) => :conflict
}
```

## Voice Model (InnerVoice)

Each voice has a volume (0..1) that determines its influence. Volume changes via:
- `amplify!(amount = 0.1)` — increases volume, clamps at 1.0
- `dampen!(amount = 0.05)` — decreases volume, clamps at 0.0
- `mute!` / `unmute!` — toggles active state without changing volume

Predicates: `dominant?` (volume >= 0.7), `quiet?` (volume <= 0.3)

## Dialogue Turn Positions

Each turn takes a position from: `:support`, `:oppose`, `:question`, `:clarify`. Unknown positions default to `:clarify`.

## Consensus Score Logic

`Dialogue#consensus_score` looks at only `:support` and `:oppose` turns (by strength sum), returning 0.5 when no directional turns exist. The score is `max(support_total, oppose_total) / (support_total + oppose_total)` — measures the degree to which one direction dominates, not which direction.

## SelfTalkEngine

Central coordinator. Holds a voices hash (keyed by voice UUID) and dialogues hash (keyed by dialogue UUID). Prunes the oldest dialogue when `MAX_DIALOGUES` is reached. `voice_balance` returns the proportional volume distribution across all voices.

## Actor

| Actor | Schedule | Runner Method |
|---|---|---|
| `VolumeDecay` | Every 300s | `decay_voices` |

`VolumeDecay` runs every 5 minutes. It calls `dampen!` on every active voice by `VOLUME_DECAY` (0.05), preventing voices from holding elevated volumes indefinitely. Voices that are never amplified will trend toward silence over time.

## LLM Enhancement

`Helpers::LlmEnhancer` provides optional LLM-powered voice generation and dialogue summarization via `legion-llm`. It is used when `Legion::LLM.started?` returns true; all calls degrade gracefully to nil on error or when LLM is unavailable.

| Method | Called From | Returns |
|---|---|---|
| `generate_turn(voice_type:, topic:, prior_turns:)` | `generate_voice_turn` (via `resolve_turn_content`) | `{ content:, position: }` |
| `summarize_dialogue(topic:, turns:)` | `conclude_dialogue` (when no `summary` provided) | `{ summary:, recommendation: }` |

`generate_turn` produces an in-character 1-3 sentence response for the given voice type, returning a position (`:support`, `:oppose`, `:question`, or `:clarify`) and content. `summarize_dialogue` synthesizes all turns into a 2-3 sentence conclusion with a recommendation (`:support`, `:oppose`, or `:abstain`).

**Fallback**: `generate_voice_turn` uses a stub string `"[voice_type perspective on topic]"` with position `:clarify` when LLM is unavailable or returns nil. `conclude_dialogue` uses `"Dialogue concluded"` as the summary when LLM is unavailable or returns nil. The `source:` field in `generate_voice_turn` response is `:llm` or `:mechanical` to indicate which path was taken.

## Integration Points

- **lex-tick**: can be wired into `action_selection` phase to deliberate before committing to an action (not currently in lex-cortex's PHASE_MAP — caller must wire manually)
- **lex-emotion**: emotional intensity can influence which voices are amplified
- **lex-cognitive-reappraisal**: reappraisal outcomes can inform which voice perspectives to amplify or dampen
- **legion-llm**: optional dependency for LLM-generated voice turns and dialogue summaries

## Development Notes

- Voice state is per-runner-instance (engine is lazily initialized with `@engine ||=`)
- `dialogue_report` maps voice UUIDs to names in `voice_positions` for human-readable output
- Inactive voices are excluded from `dominant_voice` / `quietest_voice` calculations
- `voice_balance` returns `{}` when no voices are registered (avoids division by zero)
- `generate_voice_turn` requires both the dialogue and voice to exist; returns `{ generated: false, reason: :dialogue_not_found | :voice_not_found }` if either is missing
- `decay_voices` only dampens active voices; muted voices are skipped
