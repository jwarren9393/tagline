# AGENTS.md — Tagline (for Cursor agents)

Living document. **Update this whenever you make meaningful changes.**

## What this app is

Tagline is a native Flutter desktop/mobile app (Windows, Linux, Android) that turns rough song ideas into Suno-ready **lyrics** + **style prompts** via a multi-pass NanoGPT workflow. Lyric quality (anti-cliché, concrete imagery, syllable consistency) is the core product.

## Current architecture (high level)

```
lib/
  main.dart                 # Provider bootstrap + TaglineApp
  theme/app_theme.dart      # Dark studio theme (Fraunces + Source Sans 3)
  models/
    song_idea.dart          # User intake model
    generation_result.dart  # Outputs, pipeline passes, feedback types
  data/
    cliche_families.dart    # Constrained cliché list
    genre_templates.dart    # Genre seeds, syllable targets, moods
  prompts/
    system_prompts.dart     # ALL craft expertise + few-shots + Suno rules
  services/
    secure_settings.dart    # flutter_secure_storage + SharedPreferences
    nanogpt_client.dart     # OpenAI-compatible chat completions
    lyric_pipeline.dart     # Multi-pass orchestration
    syllable_analyzer.dart  # Local syllable heuristics
    cliche_detector.dart    # Local cliché scan
  providers/
    settings_provider.dart
    generation_provider.dart  # AppView: idea | generating | results
  screens/
    home_shell.dart
    idea_intake_screen.dart
    generating_screen.dart
    results_screen.dart
    settings_screen.dart
  widgets/
    output_panel.dart, copy_button.dart, pass_progress.dart, feedback_panel.dart
```

State: **Provider**. API: **NanoGPT** (`https://nano-gpt.com/api/subscription/v1` by default, or `https://api.nano-gpt.com/api/v1`).

## Feature status

| Feature | Status |
|---------|--------|
| Idea intake (text, genre, moods, constraints) | Done |
| Multi-pass lyric + style pipeline (7 passes) | Done |
| Settings (API key, model, subscription toggle) | Done |
| Output panels + copy | Done |
| Make more specific / regen section / refine chat | Done |
| Local cliché + syllable feedback | Done |
| Genre templates | Done |
| Session history / save projects | Not started |
| Streaming pass tokens in UI | Not started |
| iOS / macOS / web | Out of scope for now |
| Offline / mock generation without API | Not started |

## Important constraints (do not break)

### Suno formatting
- **Style** = sound only (genre first, then mood, vocal, instruments, production, BPM). No story. No section tags. No inline “no X”.
- **Exclude Styles** = negatives only.
- **Lyrics** = words + `[Tags]` on their own lines. Ad-libs in `(parentheses)`.
- Reliable tags: `[Intro] [Verse] [Verse 1] [Pre-Chorus] [Chorus] [Bridge] [Instrumental Break] [Outro] [End]` (+ `[Drop] [Build] [Solo]` when relevant).
- Stay under practical limits (~1k style/exclude, ~5k lyrics).

### Lyric quality
- Expertise lives in `lib/prompts/system_prompts.dart` — keep few-shots and cliché list sharp.
- Pipeline must remain **multi-pass**; do not collapse to one-shot “write a song”.
- Prefer concrete sense-bound imagery and conversational diction (Pattison-style).

### Security
- Never commit API keys. Keys go only through `SecureSettings` / Settings UI.

## Recent decisions

- Default billing path: NanoGPT **subscription** endpoint; user can switch to pay-as-you-go API host.
- Dark “studio” UI (ink + amber + mint), not purple gradient AI defaults.
- Local feedback is heuristic guidance, not a hard gate on generation.
- Style pass failure is non-fatal if a genre style seed exists.

## Known issues / TODOs

- Widget tests may hang if Google Fonts network fetch is slow; prefer testing services in isolation.
- `OutputPanel` editable fields sync when unfocused; rapid external overwrites while typing are ignored (by design).
- No persistence of past generations yet.
- Model ID list in Settings is a convenience subset — any NanoGPT model string is allowed.
- Consider adding `json_serializable` if persistence lands.
## Agent working rules for this repo

1. After meaningful code changes, update **AGENTS.md**, **README.md**, and **PROJECT_REFERENCE.md**.
2. Prefer improving prompts/pipeline quality over adding speculative ML or complex UI.
3. Do not add web/iOS/macOS targets unless requested.
4. Keep commits focused; do not commit secrets.
