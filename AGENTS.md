# AGENTS.md — Tagline (for Cursor agents)

Living document. **Update this whenever you make meaningful changes.**

## What this app is

Tagline is a native Flutter desktop/mobile app (Windows, Linux, Android) that turns rough song ideas into Suno-ready **lyrics** + **style prompts** via a multi-pass NanoGPT workflow. Lyric quality (anti-cliché, concrete imagery, syllable consistency) is the core product.

## Current architecture (high level)

```
lib/
  main.dart
  theme/app_theme.dart
  models/
    song_idea.dart
    generation_result.dart
    generation_session.dart   # Persisted session + EvalSummary
  data/
    cliche_families.dart
    genre_templates.dart
    eval_fixtures.dart        # Good/bad fixtures for PromptEval tests
  prompts/
    system_prompts.dart       # ALL craft expertise + few-shots + Suno rules
  services/
    secure_settings.dart
    nanogpt_client.dart       # Non-stream + SSE stream chat
    lyric_pipeline.dart       # Multi-pass; streams tokens into pass.output
    history_store.dart        # JSON history in app documents dir
    prompt_eval.dart          # Deterministic quality harness
    syllable_analyzer.dart
    cliche_detector.dart
  providers/
    settings_provider.dart
    generation_provider.dart  # AppView + history + eval + throttled stream UI
  screens/
    home_shell.dart           # History + Settings actions
    idea_intake_screen.dart
    generating_screen.dart    # Live streaming pass previews
    results_screen.dart       # Eval panel + Save
    history_screen.dart
    settings_screen.dart
  widgets/
    output_panel, copy_button, pass_progress, feedback_panel, eval_panel
```

State: **Provider**. API: **NanoGPT** (subscription endpoint by default). History file: `tagline_history.json` via `path_provider`.

## Feature status

| Feature | Status |
|---------|--------|
| Idea intake (text, genre, moods, constraints) | Done |
| Multi-pass lyric + style pipeline (7 passes) | Done |
| SSE streaming into pass progress UI | Done |
| Auto-save + History screen (pin/delete/reopen) | Done |
| Prompt eval harness + fixtures/tests | Done |
| Settings (API key, model, subscription toggle) | Done |
| Output panels + copy / make specific / regen / chat | Done |
| Local cliché + syllable feedback | Done |
| Genre templates | Done |
| Export .txt / share sheet | Not started |
| LLM-as-judge secondary eval | Not started |
| Side-by-side A/B prompt experiments | Not started |
| iOS / macOS / web | Out of scope for now |
| Offline / mock generation without API | Not started |

## Important constraints (do not break)

### Suno formatting
- **Style** = sound only (genre first, then mood, vocal, instruments, production, BPM). No story. No section tags. No inline “no X”.
- **Exclude Styles** = negatives only.
- **Lyrics** = words + `[Tags]` on their own lines. Ad-libs in `(parentheses)`.
- Stay under practical limits (~1k style/exclude, ~5k lyrics).

### Lyric quality
- Expertise lives in `lib/prompts/system_prompts.dart`.
- Pipeline must remain **multi-pass**.
- When changing prompts, run `flutter test test/prompt_eval_test.dart` — good fixture must stay ≥85%, bad fixture &lt;65%.

### Security
- Never commit API keys.

## Recent decisions

- Streaming is default for all chat calls used by the pipeline (`onToken` → SSE).
- Generations auto-persist after success; manual **Save** re-evals and upserts edits.
- `PromptEval` is local/deterministic (no API) so we can regress prompt quality without Suno credits.
- Stream UI notifies are throttled (~40ms) in `GenerationProvider`.
- Platforms remain Windows / Linux / Android only — do not add a `web/` target unless explicitly requested.

## Known issues / TODOs

- Widget pumps of full `TaglineApp` can hang on Google Fonts; keep tests service-level.
- `OutputPanel` ignores external text updates while focused (by design).
- History has no search/filter yet.
- If a host fails SSE, client falls back to non-stream once for empty buffers.

## Agent working rules for this repo

1. After meaningful code changes, update **AGENTS.md**, **README.md**, and **PROJECT_REFERENCE.md**.
2. Prefer improving prompts/pipeline quality over speculative ML or complex UI.
3. Do not add web/iOS/macOS targets unless requested.
4. Keep commits focused; do not commit secrets.
