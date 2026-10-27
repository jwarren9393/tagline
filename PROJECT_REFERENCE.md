# PROJECT_REFERENCE.md — Tagline

Comprehensive reference for AI systems (Grok, Gemini, Cursor, etc.) continuing work on this project. **Keep synchronized with the codebase.**

---

## 1. Background and goals

**Tagline** is a native Flutter application for Windows, Linux, and Android. It is an expert **pre-production** companion for **Suno AI** (Premier plan, including Studio / Custom Mode).

### Problem
Suno’s first generations are only as good as the lyrics and style prompt. Typical LLM lyrics are full of clichés, abstract emotion, inconsistent syllable counts, and formatting that fights Suno’s model. Users burn credits in a generate–wait–rewrite loop.

### Solution
The user enters a rough idea. Tagline runs a **multi-pass LLM pipeline** (NanoGPT) that produces:

1. **Structured song lyrics** with Suno section tags on their own lines.
2. A **front-loaded Style prompt** optimized for current Suno (v6 family) plus **Exclude Styles**.

Quality is enforced primarily through **system prompts, few-shot examples, and multi-pass rewriting**, not custom ML models.

---

## 2. Repository and platforms

- **GitHub:** https://github.com/jwarren9393/tagline (public)
- **Package name:** `tagline`
- **Org / Android applicationId:** `com.tagline.tagline`
- **Targets:** `windows`, `linux`, `android` only (no web/iOS/macOS in current scope)
- **Flutter:** 3.47+ / Dart 3.13+ (SDK constraint `^3.13.5`)

### Living documents (always update)
| File | Audience |
|------|----------|
| `README.md` | Users / GitHub |
| `AGENTS.md` | Cursor agents |
| `PROJECT_REFERENCE.md` | Other AIs / deep context |

---

## 3. Technical architecture

### 3.1 Stack
- Flutter Material 3
- **State management:** `provider` (`SettingsProvider`, `GenerationProvider`)
- **HTTP:** `http` package → NanoGPT OpenAI-compatible Chat Completions
- **Secrets:** `flutter_secure_storage` (API key)
- **Prefs:** `shared_preferences` (model ID, subscription toggle)
- **Fonts:** `google_fonts` (Fraunces display, Source Sans 3 body)
- **IDs:** `uuid` (available; not heavily used yet)

### 3.2 Directory map

```
lib/
  main.dart
  theme/app_theme.dart
  models/
    song_idea.dart              # mode: generate | rescue; optional InspirationDna / LyricRescueInput
    inspiration_dna.dart        # + AudioProfile (BPM/duration/gain)
    lyric_rescue_input.dart
    generation_result.dart, generation_session.dart
  data/cliche_families.dart, genre_templates.dart, eval_fixtures.dart
  prompts/system_prompts.dart          # CORE EXPERTISE (craft + DNA + rescue + judge + A/B)
  services/
    nanogpt_client.dart, nanogpt_catalog_service.dart
    lyric_pipeline.dart                # generate + rescue + A/B branch
    inspiration_dna_service.dart
    musicbrainz_client.dart, genius_client.dart, deezer_client.dart
    track_match.dart                   # strict title match shared by Genius/Deezer
    history_store.dart, export_service.dart
    prompt_eval.dart, llm_judge.dart
    syllable_analyzer.dart, cliche_detector.dart, secure_settings.dart
  providers/settings_provider.dart, generation_provider.dart
  screens/
    home_shell.dart                    # New song / Lyric Rescue segmented switcher
    idea_intake_screen.dart, lyric_rescue_screen.dart
    generating_screen.dart, results_screen.dart, history_screen.dart
    settings_hub_screen.dart, api_settings_screen.dart
  widgets/...
```

### 3.3 App navigation / views

`GenerationProvider.view` drives a single-shell navigation:

| `AppView` | Screen | Role |
|-----------|--------|------|
| `idea` | `IdeaIntakeScreen` | Free text + genre/mood/constraints + Inspiration DNA |
| `rescue` | `LyricRescueScreen` | Paste existing Suno lyrics/style + creator intent |
| `generating` | `GeneratingScreen` | Per-pass progress list (generate or rescue) |
| `results` | `ResultsScreen` | Lyrics / Style / Exclude + tools + refine chat |

Home intake shows a **New song / Lyric Rescue** segmented control. Settings is a pushed hub (`SettingsHubScreen` → `ApiSettingsScreen`), not an `AppView`.

**Inspiration DNA** (idea intake): artist / song / optional paste → MusicBrainz tags + Genius ephemeral lyrics analysis + Deezer BPM/duration/gain → NanoGPT abstract formula. Genius lyrics are analysis-only and must not appear in Style/Lyrics outputs. Each enrichment source only attaches on a real match (miss > wrong song). Measured Deezer audio seeds Style (BPM may be half-timed for ballads).

**Lyric Rescue** (`AppView.rescue`): paste existing Suno lyrics + optional Style/Exclude + creator intent → `LyricPipeline.rescue` → same results/export pack. Sessions auto-tag `rescue`. By default Rescue keeps section skeleton/length and may protect a strong original chorus for remix continuity; put tighten/chorus-rewrite asks in creator notes.

### 3.4 Data flow

```
User SongIdea (mode=generate)
    → LyricPipeline.generate()
        → NanoGptClient.chat() × N passes
        → GenerationResult { lyrics, stylePrompt, excludeStyles, title, notes, passArtifacts }

User SongIdea (mode=rescue, LyricRescueInput)
    → LyricPipeline.rescue()
        → diagnose → rewrite → anti-slop → optimize → style remaster
        → GenerationResult (same shape)

    → SyllableAnalyzer + ClicheDetector → LyricFeedback
    → UI panels (editable) + copy / share pack
```

Refinement paths (post-generate):
- `makeMoreSpecific()` — full lyrics rewrite for concreteness
- `regenerateSection(sectionTag)` — rewrite one tagged section, return full lyrics
- `sendChat(message)` — conversational refine with current lyrics/style in context
- `regenerateFromPrompt()` / `rescueLyrics()` — re-run generate or rescue for the active mode

---

## 4. NanoGPT integration

### Endpoints (bases; client appends `/chat/completions`)
- Subscription (default on): `https://nano-gpt.com/api/subscription/v1`
- Pay-as-you-go: `https://nano-gpt.com/api/v1`

### Auth
`Authorization: Bearer <API_KEY>`

### Request shape
OpenAI-compatible non-streaming JSON:
```json
{
  "model": "<nanogpt model id>",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."}
  ],
  "temperature": 0.3–0.85,
  "stream": false
}
```

### Settings fields
- API key → secure storage key `nanogpt_api_key`
- Model → prefs `nanogpt_model` (default `openai/gpt-4o`)
- Use subscription → prefs `nanogpt_use_subscription` (default `true`)

Client: `lib/services/nanogpt_client.dart`  
JSON extraction helper: `extractJsonObject()` (handles fences / surrounding prose).

---

## 5. Multi-pass generation pipeline

Implemented in `lib/services/lyric_pipeline.dart`.

### 5.1 Generate (`LyricPipeline.generate`)

| # | id | Purpose | System prompt factory |
|---|-----|---------|------------------------|
| 0 | `inspiration` | Optional abstract DNA from artist/song/paste | `inspirationDnaSystem` + MusicBrainz + Genius + Deezer |
| 1 | `scenes` | Voice brief + tiny optional detail bank | `sceneExtractionSystem` → JSON |
| 2 | `arc` | Emotional/story arc + section jobs + hook | `arcOutlineSystem` → JSON |
| 3 | `draft` | Singable lyrics + rhyme + tags | `draftLyricsSystem` → lyrics |
| 4 | `cliche` | Anti-slop / voice + rhyme rewrite | `clicheRewriteSystem` → lyrics |
| 5 | `optimize` | Final polish + structure/chorus + title | `sunoOptimizeSystem` → JSON `{title,lyrics,notes}` |
| 6 | `style` | Style + Exclude Styles | `stylePromptSystem` → JSON `{style,exclude_styles}` |

No separate structure LLM pass (draft + optimize own tags/chorus). Temperatures tuned per pass. Style failure is non-fatal if a genre `styleSeed` exists.

### 5.2 Lyric Rescue (`LyricPipeline.rescue`)

| # | id | Purpose | System prompt factory |
|---|-----|---------|------------------------|
| 0 | `diagnose` | Keep vs fix; structure notes | `rescueDiagnoseSystem` → JSON |
| 1 | `rewrite` | Remaster lyrics; keep soul/skeleton | `rescueRewriteSystem` → lyrics |
| 2 | `cliche` | Anti-slop polish | `clicheRewriteSystem` → lyrics |
| 3 | `optimize` | Final polish + title | `sunoOptimizeSystem` → JSON |
| 4 | `style` | Remaster Style/Exclude for paste-back | `rescueStyleSystem` → JSON |

Input model: `LyricRescueInput` (title, lyrics, stylePrompt, excludeStyles, creatorNotes) stored on `SongIdea.rescue` with `mode: 'rescue'`.

**Expectation:** Rescue preserves section length/skeleton by default (an 8-line verse stays ~8 lines). New-song generation aims tighter (~6–10 syllables/line). Users who want shorter verses or a rewritten chorus should say so in creator notes.

Progress is reported via `PassProgressCallback` → UI `PassProgressList`.

---

## 6. Suno-specific rules (encode in prompts; enforce in UX copy)

### Field separation
- **Style field:** sound only — genre/subgenre **first** (strongest signal), then mood/energy, vocal character/delivery, instruments + what they do, production/era, BPM. Front-load. Focused. No story, no lyrics, no `[tags]`, no “no X”.
- **Exclude Styles:** all negatives.
- **Lyrics field:** words + structure tags.

### Structure tags (own line, square brackets)
Reliable: `[Intro]`, `[Verse]`, `[Verse 1]`, `[Verse 2]`, `[Pre-Chorus]`, `[Chorus]`, `[Bridge]`, `[Instrumental Break]`, `[Outro]`, `[End]`.  
Genre-appropriate: `[Drop]`, `[Build]`, `[Solo]`.  
At most one short delivery cue inside a tag if needed. Ad-libs/backing vocals in `(parentheses)`.

### Character budgets
~1000 Style / Exclude; ~5000 Lyrics. Truncate style/exclude to ~900 in pipeline as a safety rail.

### Style prompt pattern (example shape, not to copy verbatim)
`genre/subgenre, mood/energy, vocal character, key instruments and roles, production/era, BPM`

---

## 7. Anti-cliché and lyric craft

### Principles (prompted + locally scanned)
1. **Show, don’t tell** — sense-bound, filmable details (Pattison object-writing inspiration). Prefer “cold coffee still sitting on the counter” over “I feel empty.”
2. **Conversational** — how people speak; avoid purple prose.
3. **Syllable consistency** within sections (pop/rock verse ~6–10; chorus shorter; rap higher).
4. **Chorus** — short, verbatim-repeatable, prefer open vowels for sustain.
5. **Earn clichés** or replace them.

### Cliché families
Canonical list: `lib/data/cliche_families.dart` (neon lights, broken heart, forever, fading, shadows, rising above, fire/burn, rain/tears, stars/destiny, empty feelings, chasing dreams, generic midnight, whispers/secrets, soulmate). Injected into prompts; scanned by `ClicheDetector`.

### Local feedback UI
`SyllableAnalyzer` + `ClicheDetector` → `FeedbackPanel` on results screen. Heuristic only.

### Few-shots
Embedded in `SystemPrompts.fewShotGoodVsBad` — good vs bad verse/chorus examples. Extend carefully; do not paste copyrighted songs.

---

## 8. Genre templates

`lib/data/genre_templates.dart` provides:
- `styleSeed`, `excludeSeed`
- `structureHint`
- `verseSyllables` / `chorusSyllables`
- Mood chip list `kMoodOptions`

Templates seed the style pass and appear in the idea prompt block. They are starting points, not hard locks.

---

## 9. UI design notes

- Dark studio aesthetic: ink backgrounds, amber primary, mint secondary (`AppColors`).
- Brand “Tagline” is prominent on the idea intake first viewport.
- Avoid purple-on-white / cream-serif terracotta AI clichés.
- Cards used only as interactive/output containers with subtle borders (no heavy shadows).
- Responsive: wide layouts split idea form / genre panel and lyrics / style columns.

---

## 10. Platform-specific notes

### Linux
Requires Flutter Linux desktop dependencies (GTK). Run: `flutter run -d linux`.

### Windows
Requires Visual Studio desktop C++ workload. Run: `flutter run -d windows`.

### Android
Standard Flutter Android project under `android/`. Secure storage uses platform defaults (flutter_secure_storage 11.x AndroidOptions API changed — do not use removed `encryptedSharedPreferences` named param).

### Network
App needs internet for NanoGPT and (on first run) Google Fonts download. Offline generation is not implemented.

---

## 11. Testing

```bash
flutter analyze
flutter test
```

Prefer unit tests for pipeline helpers (`syllable_analyzer_test.dart`, idea prompt block). Full widget pumps of `TaglineApp` can hang on Google Fonts network fetch — avoid in CI without font mocking.

---

## 12. Generation history

- Model: `GenerationSession` (`id`, timestamps, `SongIdea`, `GenerationResult`, optional `EvalSummary`, `pinned`)
- Store: `HistoryStore` → `tagline_history.json` in application documents directory (`path_provider`)
- Cap: 200 sessions (drops oldest unpinned first)
- Auto-upsert after successful generate and after tools that change lyrics; manual **Save** on results screen
- UI: `HistoryScreen` (open / pin / delete / import / export)
- Portable transfer: `ExportService` writes `.tagline.json` envelopes (`tagline.session` / `tagline.history`); import upserts by id via `HistoryStore.upsertAll`
- Suno pack share: file-only on mobile (`share_plus` freezes if `text` + `files` are both set); desktop uses `FilePicker.saveFile`

## 13. Streaming

- `NanoGptClient.chatStream` / `chat(..., onToken:)` uses SSE (`Accept: text/event-stream`, `stream: true`)
- Pipeline passes update `PipelinePass.output` live; `PassProgressList` shows a scrolling monospace preview
- `GenerationProvider` throttles `notifyListeners` (~40ms) during streams
- Empty stream buffer falls back to a non-stream request once

## 14. Prompt eval harness

- Service: `PromptEval` → `EvalSummary` with weighted checks:
  - structure tags, chorus present/verbatim, tags on own lines
  - style: no story/tags, no inline negatives, genre-first, BPM/tempo
  - char budgets, cliché density, syllable consistency, line length
- Fixtures: `lib/data/eval_fixtures.dart` (synthetic good vs bad)
- Tests: `test/prompt_eval_test.dart` — **good ≥ 85%**, **bad &lt; 65%**
- Shown on results via `EvalPanel`; score stored on sessions

When changing prompts or craft rules, update fixtures if needed and keep the regression gate green:
```bash
flutter test test/prompt_eval_test.dart
```

## 15. How to extend (guidance for future AIs)

### Improving lyric quality
1. Edit `lib/prompts/system_prompts.dart` few-shots and rules first — optimize for **human voice + section turns**, not prop dumps.
2. Expand `cliche_families.dart` for both classic clichés and AI pastiche (kitchen props, recovery-diary cosplay, metaphor salad).
3. Keep `prompt_eval_test` green; tighten checks before adding LLM-as-judge.
4. Model picks: pay-as-you-go Claude Opus 5.5 / Fable 5.1 / Sonnet 5.5; subscription try GLM 5.3, DeepSeek V4 Pro / V3.1, Llama 4 Maverick.

### Natural next features
- Offline mock generation
- Stronger Rescue controls (verse length / chorus rewrite toggles) instead of notes-only
- Suno remix/cover workflow guidance once product-side options are clearer
- Cross-device sync beyond portable `.tagline.json`

### Do not
- Collapse to single-shot generation for “speed.”
- Put story or tags in the Style field.
- Commit API keys.
- Copy copyrighted lyrics or proprietary Suno prompt packs verbatim.
- Attach Genius/Deezer metadata for the wrong song (miss > wrong match).


---

## 16. Mobile UX notes

- `SafeArea(bottom: true)` on `HomeShell` / History / Settings; `SystemUiOverlayStyle` for nav bar contrast.
- Editable multiline fields use `maxLines: null` (grow with content) so parent `SingleChildScrollView` / `CustomScrollView` receives vertical drags — avoids “must scroll in the tiny gutter” on phones.
- `keyboardDismissBehavior: onDrag` on major scroll views.
- Android `INTERNET` permission declared; `windowSoftInputMode=adjustResize`.

## 17. Prompt reuse

- Results screen **Your prompt** / **Rescue intent** panel edits `SongIdea.rawIdea` (and rescue creator notes when `mode == rescue`).
- Actions: **Regenerate / Re-rescue** (same session), **Edit as new idea / Edit rescue paste** (intake with text preserved via `ideaEditToken`).
- History tile **Reuse prompt** loads idea into the matching intake (`idea` vs `rescue`) without opening outputs.

## 18. Export, feedback, judge, A/B

- `ExportService.buildPack` / `sharePack` — Style, Exclude, Lyrics, original prompt.
- `sunoFeedback` on session; included in Refine context.
- `LlmJudge` → JSON score/summary/strengths/fixes; stored as `llmJudgeNotes`.
- `runAbExperiment` reuses `passArtifacts['scenes'|'arc']`, runs branch A (standard draft) vs B (`draftLyricsSystemVariantB`), keeps higher `PromptEval` lyrics; stores `AbComparison` + both lyrics in artifacts.

## 19. API & connection (Anima-parity)

Settings screen rebuilt to match Anima’s NanoGPT connection UX (Tagline theme):
- Key save/remove via secure storage (separate from model save)
- Credits sheet: `POST /api/check-balance` + `GET /api/subscription/v1/usage` in parallel
- Live catalog: `GET {baseUrl}/models?detailed=true`
- Filters: Category (incl. broad uncensored) → Min context → Provider (Auto first)
- Selected model card + Browse sheet (search, perf filters/sort, favorites)
- Runtime stats: `GET /api/models/{id}/providers` (TPS/TTFT/uptime), session-cached
- Subscription toggle switches base URL and reloads catalog
  - Off: `https://nano-gpt.com/api/v1`
  - On: `https://nano-gpt.com/api/subscription/v1`
- No image-model UI (Tagline does not generate images)
- Code: `lib/models/nanogpt_catalog.dart`, `lib/services/nanogpt_catalog_service.dart`,
  `lib/screens/settings_screen.dart`, `lib/widgets/browse_models_sheet.dart`, `credits_sheet.dart`

## 20. Current implementation snapshot

As of Inspiration DNA + Lyric Rescue:
- Home modes: **New song** and **Lyric Rescue** (segmented switcher)
- Inspiration DNA: MusicBrainz + Genius + Deezer (strict title match) → abstract formula + measured audio baseline
- Lyric Rescue: diagnose → rewrite → anti-slop → optimize → style remaster; sessions tagged `rescue`
- SafeArea / scroll-from-field fixes
- Prompt visibility + regenerate / new-idea / history reuse (mode-aware)
- Export/share (Suno pack + portable `.tagline.json` session/history), Suno feedback, history search+tags, LLM judge, A/B
- Live NanoGPT catalog / credits / favorites settings (Anima-parity UX)
- Prior: streaming, history persistence, local eval, multi-pass, expanded genre/mood favorites
- Dependencies: `share_plus`, `path_provider`, `path`, `file_picker`, …
- Platforms: Windows, Linux, Android only
- Not yet: offline mock generation, cross-device sync, Rescue length/chorus UI toggles

When you change any of the above, update this file, `AGENTS.md`, and `README.md`.
