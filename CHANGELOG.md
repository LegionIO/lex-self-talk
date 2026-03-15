# Changelog

## [0.1.1] - 2026-03-14

### Added
- VolumeDecay periodic actor (Every 300s) — calls `decay_voices` to dampen all active voice volumes toward baseline, preventing voices from holding elevated volumes indefinitely
- Optional LLM enhancement via Helpers::LlmEnhancer — `generate_turn(voice_type:, topic:, prior_turns:)` generates realistic in-character inner voice turns for a given voice type and dialogue context; `summarize_dialogue(topic:, turns:)` synthesizes a completed dialogue into a conclusion with a recommendation

## [0.1.0] - 2026-03-13

### Added
- Initial release
