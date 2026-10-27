# AGENTS.md — Tagline (for Cursor agents)

Living document. **Update this whenever you make meaningful changes.**

## What this app is

Tagline is a native Flutter desktop/mobile app (Windows, Linux, Android) that turns rough song ideas into Suno-ready **lyrics** + **style prompts** via a multi-pass NanoGPT workflow. Lyric quality is the core product: **human voice + substance**, not prop inventories or classic clichés.

## Current architecture (high level)

```
lib/
  main.dart
  theme/app_theme.dart
  models/
    song_idea.dart, inspiration_dna.dart  # + AudioProfile (BPM etc.)
    lyric_rescue_input.dart               # paste-back remaster input
    generation_result.dart
    generation_session.dart   # + tags, sunoFeedback, llmJudgeNotes, AbComparison
  data/
    cliche_families.dart, genre_templates.dart, eval_fixtures.dart
  prompts/system_prompts.dart # craft + judge + A/B + inspiration DNA
  services/
    nanogpt_client.dart       # SSE streaming
    lyric_pipeline.dart       # generate + rescue + generateLyricBranch (A/B)
    inspiration_dna_service.dart
    musicbrainz_client.dart, genius_client.dart, deezer_client.dart
    track_match.dart          # strict title match (miss > wrong song)
    history_store.dart
    prompt_eval.dart          # local harness
    llm_judge.dart            # optional LLM second opinion
    export_service.dart       # copy/share Suno pack
    syllable_analyzer.dart, cliche_detector.dart, secure_settings.dart
  providers/generation_provider.dart  # AppView: idea | rescue | generating | results
  screens/
    home_shell.dart           # SafeArea + New song / Lyric Rescue switcher
    idea_intake_screen.dart  # genre/mood favorite pickers + growing fields
    lyric_rescue_screen.dart # paste existing Suno lyrics/style → remaster
    generating_screen.dart, results_screen.dart, history_screen.dart
    settings_hub_screen.dart, api_settings_screen.dart
  widgets/
    output_panel.dart         # growing editable fields for page scroll
    favorite_picker_field.dart
    pass_progress, eval_panel, feedback_panel, copy_button
```

## Feature status

| Feature | Status |
|---------|--------|
| Idea intake / multi-pass / streaming | Done |
| Expanded genre/mood catalogs + favorite dropdowns | Done |
| Settings hub + API submenu | Done |
| Inspiration DNA (MB + Genius + Deezer BPM → abstract formula) | Done |
| Lyric Rescue (paste Suno lyrics/style → craft remaster) | Done |
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
| Portable session import/export (`.tagline.json`) | Done |
| Share Suno pack (file-only; desktop save dialog) | Done |
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
- Share must not pass `text` and `files` together to `share_plus` (Android freeze). Desktop uses `FilePicker.saveFile` instead of a share sheet.
- Session transfer files use envelope `{format:"tagline.session"|"tagline.history", version, session(s)}`; import upserts by id so the same file restores/updates across devices.
- Craft target is **a song with a human voice**: end rhyme (AABB/ABAB) + even meter + substance. Ban AI kitchen/recovery/bathroom-mirror pastiche, unrhymed free-verse talk, workshop-forced rhymes, pad repeats, and overlong bridges. One earned detail beats a prop dump. Scene bank is optional ammo, not a checklist. Hooks must be song-specific (no recycled demo chorus DNA).
- Inspiration DNA is **formula only**: MusicBrainz tags + Genius song match (ephemeral lyrics for analysis) + Deezer measured BPM/duration/gain + optional user paste → NanoGPT distill. Genius lyrics are never persisted into outputs/exports; never reproduce copyrighted lines. Measured audio feeds Style baseline (half-time ok for ballad/R&B). DNA feeds Generate as abstract constraints.
- Lyric Rescue is a separate home mode (`AppView.rescue`): paste existing Suno lyrics (+ optional Style/Exclude + creator intent) → diagnose → rewrite → anti-slop → optimize → style remaster. Keeps song soul + **section skeleton/length** unless creator notes ask to tighten (e.g. “cut verses to 4 lines”). Chorus may stay close for remix continuity — tell Rescue explicitly if the chorus needs a craft rewrite. Output is a Suno pack for remix/cover/reuse (Suno-side remix UX left to the user). Sessions auto-tag `rescue`.
- Generate pipeline is 6 LLM passes (no separate structure pass). Rescue is 5 passes (diagnose/rewrite/cliche/optimize/style). Local eval ignores chorus ad-lib variance, allows musical “chorus” in Style, and checks verse end-rhyme heuristically.
- Model shortlist (also in Settings chips): sub `deepseek/deepseek-v4-pro`, `z-ai/glm-5.3`, `meta-llama/llama-4-maverick`; PAYG quality `anthropic/claude-sonnet-5.5`, `anthropic/claude-opus-5.5`.

## Known issues / TODOs

- Full `TaglineApp` widget tests can hang on Google Fonts — keep service tests.
- A/B does not regenerate Style (keeps current style for scoring consistency).
- Share sheet behavior varies by Android OEM.
- Deezer/Genius only attach on a real title match (miss > wrong song). Deezer BPM coverage is incomplete (bpm=0 or track absent → that source omitted; DNA stays partial).
- Lyric Rescue can leave epic/original choruses mostly intact and preserve long verses unless the user asks to compress — expect remaster continuity over New-song tightness by default.

## Agent working rules

1. Update **AGENTS.md**, **README.md**, **PROJECT_REFERENCE.md** after meaningful changes.
2. Prefer prompt/pipeline quality over speculative UI.
3. No web/iOS/macOS unless requested.
4. No secrets in git.
