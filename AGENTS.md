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
    generation_session.dart   # + tags, sunoFeedback, llmJudgeNotes, AbComparison
  data/
    cliche_families.dart, genre_templates.dart, eval_fixtures.dart
  prompts/system_prompts.dart # craft + judge + A/B variant B draft
  services/
    nanogpt_client.dart       # SSE streaming
    lyric_pipeline.dart       # multi-pass + generateLyricBranch (A/B)
    history_store.dart
    prompt_eval.dart          # local harness
    llm_judge.dart            # optional LLM second opinion
    export_service.dart       # copy/share Suno pack
    syllable_analyzer.dart, cliche_detector.dart, secure_settings.dart
  providers/generation_provider.dart
  screens/
    home_shell.dart           # SafeArea + system nav bar styling
    idea_intake_screen.dart  # growing TextFields (maxLines: null)
    generating_screen.dart, results_screen.dart, history_screen.dart, settings_screen.dart
  widgets/
    output_panel.dart         # growing editable fields for page scroll
    pass_progress, eval_panel, feedback_panel, copy_button
```

## Feature status

| Feature | Status |
|---------|--------|
| Idea intake / multi-pass / streaming | Done |
| SafeArea vs Android gesture/nav bar | Done |
| Growing fields so page scroll works from inside inputs | Done |
| View/edit original prompt on results; regenerate / new idea | Done |
| History reuse-prompt action | Done |
| History search + tag filter; session tags | Done |
| Export: copy pack + share sheet (`share_plus`) | Done |
| Suno feedback notes (saved + fed into Refine) | Done |
| Local prompt eval + LLM judge | Done |
| A/B lyric branch experiment (A standard / B specificity) | Done |
| Anima-style API & connection settings (catalog/credits/favorites) | Done |
| Offline mock generation | Not started |
| iOS / macOS / web | Out of scope |

## Important constraints

- Suno Style = sound only; Exclude = negatives; Lyrics = words + `[tags]`.
- Multi-pass required; keep `prompt_eval_test` green when changing craft rules.
- Never commit API keys.
- Platforms: Windows / Linux / Android only.

## Recent decisions

- Multiline fields use `maxLines: null` so the **parent** `ScrollView` owns vertical drag (fixes phone scroll-from-field).
- `HomeShell` uses `SafeArea(bottom: true)` + nav bar `SystemUiOverlayStyle` so UI clears the system gesture bar.
- Results always show **Your prompt** with regenerate / edit-as-new.
- A/B reuses scene+arc artifacts; only re-runs draft→optimize for variants A/B; keeps higher local eval.
- Refine chat includes original prompt + Suno feedback + LLM judge notes when present.
- API settings follow Anima NanoGPT UX (not theme): live `models?detailed=true`, credits sheet (wallet + subscription usage), filters, browse sheet, favorites, separate key vs model saves. Pay-as-you-go base = `https://nano-gpt.com/api/v1`. No image-model section (Tagline does not generate images).

## Known issues / TODOs

- Full `TaglineApp` widget tests can hang on Google Fonts — keep service tests.
- A/B does not regenerate Style (keeps current style for scoring consistency).
- Share sheet behavior varies by Android OEM.

## Agent working rules

1. Update **AGENTS.md**, **README.md**, **PROJECT_REFERENCE.md** after meaningful changes.
2. Prefer prompt/pipeline quality over speculative UI.
3. No web/iOS/macOS unless requested.
4. No secrets in git.
