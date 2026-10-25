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
  models/song_idea.dart
  models/generation_result.dart
  data/cliche_families.dart
  data/genre_templates.dart
  prompts/system_prompts.dart          # CORE EXPERTISE
  services/secure_settings.dart
  services/nanogpt_client.dart
  services/lyric_pipeline.dart         # CORE ORCHESTRATION
  services/syllable_analyzer.dart
  services/cliche_detector.dart
  providers/settings_provider.dart
  providers/generation_provider.dart
  screens/home_shell.dart
  screens/idea_intake_screen.dart
  screens/generating_screen.dart
  screens/results_screen.dart
  screens/settings_screen.dart
  widgets/...
```

### 3.3 App navigation / views

`GenerationProvider.view` drives a single-shell navigation:

| `AppView` | Screen | Role |
|-----------|--------|------|
| `idea` | `IdeaIntakeScreen` | Free text + genre/mood/constraints |
| `generating` | `GeneratingScreen` | Per-pass progress list |
| `results` | `ResultsScreen` | Lyrics / Style / Exclude + tools + refine chat |

Settings is a pushed route (`SettingsScreen`), not an `AppView`.

### 3.4 Data flow

```
User SongIdea
    → LyricPipeline.generate()
        → NanoGptClient.chat() × N passes
        → GenerationResult { lyrics, stylePrompt, excludeStyles, title, notes, passArtifacts }
    → SyllableAnalyzer + ClicheDetector → LyricFeedback
    → UI panels (editable) + copy to clipboard
```

Refinement paths (post-generate):
- `makeMoreSpecific()` — full lyrics rewrite for concreteness
- `regenerateSection(sectionTag)` — rewrite one tagged section, return full lyrics
- `sendChat(message)` — conversational refine with current lyrics/style in context

---

## 4. NanoGPT integration

### Endpoints
- Subscription (default): `https://nano-gpt.com/api/subscription/v1/chat/completions`
- Direct API: `https://api.nano-gpt.com/api/v1/chat/completions`

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

Implemented in `lib/services/lyric_pipeline.dart`. Passes (in order):

| # | id | Purpose | System prompt factory |
|---|-----|---------|------------------------|
| 1 | `scenes` | Extract/invent concrete sensory bank + objects | `sceneExtractionSystem` → JSON |
| 2 | `arc` | Emotional/story arc + section jobs + hook | `arcOutlineSystem` → JSON |
| 3 | `draft` | Conversational lyrics + tags | `draftLyricsSystem` → lyrics |
| 4 | `structure` | Normalize Suno tags, chorus identity | `structurePassSystem` → lyrics |
| 5 | `cliche` | Anti-cliché / specificity rewrite | `clicheRewriteSystem` → lyrics |
| 6 | `optimize` | Final Suno delivery polish | `sunoOptimizeSystem` → JSON `{title,lyrics,notes}` |
| 7 | `style` | Style + Exclude Styles | `stylePromptSystem` → JSON `{style,exclude_styles}` |

Temperatures are tuned per pass (creative early, stricter late). Style failure is non-fatal if a genre `styleSeed` exists.

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
1. Edit `lib/prompts/system_prompts.dart` few-shots and rules first.
2. Expand `cliche_families.dart` only with high-frequency offenders.
3. Keep `prompt_eval_test` green; tighten checks before adding LLM-as-judge.

### Natural next features
- Export lyrics/style as `.txt` / share sheet
- History search + tags
- Optional LLM judge pass scored against the same rubric
- A/B prompt experiment mode using eval scores
- User “reference generation notes” after pasting into Suno (close the feedback loop)

### Do not
- Collapse to single-shot generation for “speed.”
- Put story or tags in the Style field.
- Commit API keys.
- Copy copyrighted lyrics or proprietary Suno prompt packs verbatim.

---

## 16. Mobile UX notes

- `SafeArea(bottom: true)` on `HomeShell` / History / Settings; `SystemUiOverlayStyle` for nav bar contrast.
- Editable multiline fields use `maxLines: null` (grow with content) so parent `SingleChildScrollView` / `CustomScrollView` receives vertical drags — avoids “must scroll in the tiny gutter” on phones.
- `keyboardDismissBehavior: onDrag` on major scroll views.
- Android `INTERNET` permission declared; `windowSoftInputMode=adjustResize`.

## 17. Prompt reuse

- Results screen **Your prompt** panel edits `SongIdea.rawIdea`.
- Actions: **Regenerate from this prompt** (same session), **Edit as new idea** / **New from prompt** (intake with text preserved via `ideaEditToken`).
- History tile **Reuse prompt** loads idea into intake without opening outputs.

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

As of the Anima-style API settings milestone:
- SafeArea / scroll-from-field fixes
- Prompt visibility + regenerate / new-idea / history reuse
- Export/share (Suno pack + portable `.tagline.json` session/history), Suno feedback, history search+tags, LLM judge, A/B
- Live NanoGPT catalog / credits / favorites settings
- Prior: streaming, history persistence, local eval, multi-pass, genre templates
- Dependencies: `share_plus`, `path_provider`, `path`, …
- Platforms: Windows, Linux, Android only
- Not yet: offline mock generation, cross-device sync

When you change any of the above, update this file, `AGENTS.md`, and `README.md`.
