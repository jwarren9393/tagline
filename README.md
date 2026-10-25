# Tagline

**Expert pre-production tool for [Suno AI](https://suno.com)** (Premier / Studio).

Tagline turns a rough song idea — theme, mood, story fragments, genre preference, reference vibes — into high-quality **Suno-ready lyrics** and a clean, front-loaded **Style prompt** (plus Exclude Styles). Paste the outputs into Custom Mode / Studio and get better first-generation results with less generate–wait–rewrite.

## Who it’s for

Songwriters and producers who use Suno and want lyrics that actually sing: concrete imagery, conversational language, consistent syllable counts, and proper structure tags — not AI cheese.

## Key features

- **Multi-pass generation** (not one-shot): scene/sensory extraction → story arc → draft → structure tags → anti-cliché rewrite → Suno optimize → style prompt
- **Live streaming** of each pass into the progress UI (SSE via NanoGPT)
- **Original prompt on results** — view/edit, regenerate from it, or start a new idea; reuse from History
- **Suno-accurate formatting**: section tags on their own lines; Style = sound only; negatives in Exclude Styles
- **Anti-cliché craft** + local **prompt eval** + optional **LLM judge**
- **A/B test** lyric variants (standard vs specificity-first); keeps the higher eval score
- **Suno feedback loop** — note what rushed/worked after generating in Suno; feeds Refine
- **Export** — copy full pack or share `.txt` (Style + Exclude + Lyrics + original prompt)
- **History** — auto-save, pin, search, tags, reopen, reuse prompt
- **Mobile-friendly layout** — clears system nav/gesture bar; page scrolls from inside text fields
- **Genre templates**, section regen, refinement chat
- **Anima-style API & connection** — live model catalog, credits sheet, favorites, subscription toggle
- **Secure NanoGPT API key** storage (`flutter_secure_storage`)

## Platforms

Native Flutter app for **Windows**, **Linux**, and **Android**. No web build.

## Setup

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) 3.24+ (tested on 3.47)
- A [NanoGPT](https://nano-gpt.com) account/API key (subscription recommended)
- Platform toolchains as needed (Android SDK, Linux GTK deps, Windows Visual Studio)

### Install & run

```bash
git clone https://github.com/jwarren9393/tagline.git
cd tagline
flutter pub get
```

**Linux**

```bash
flutter run -d linux
# or
flutter build linux
```

**Windows**

```bash
flutter run -d windows
# or
flutter build windows
```

**Android**

```bash
flutter run -d android
# or
flutter build apk
```

### First launch

1. Open **Settings** (gear icon).
2. Paste your NanoGPT API key and save.
3. Prefer **subscription endpoint** if you use a NanoGPT subscription.
4. Pick a model ID from the NanoGPT catalog (defaults to `openai/gpt-4o`).
5. Return home, enter a song idea, optionally pick genre/moods, then **Generate**.

## Basic usage

1. Describe the song in plain language. Specific objects and scenes help.
2. Optionally load a **genre template** and select moods / constraints.
3. Wait for the multi-pass pipeline (progress is shown per pass).
4. Copy **Lyrics** into Suno’s Lyrics field and **Style** / **Exclude Styles** into the matching fields.
5. On results, your **prompt** stays editable — regenerate from it or “Edit as new idea.”
6. Check **Prompt eval**; optionally run **LLM judge** or **A/B test**.
7. **Copy pack** / **Share** into Suno (desktop saves a `.txt`; Android opens the share sheet with the pack file). Afterward fill **Suno feedback** so Refine can target real delivery issues.
8. **Export session** / History **Import** / **Export all** move sessions as `.tagline.json` between desktop and Android (upsert by id).
9. History supports search, tags, and **reuse prompt**.

## Project docs

| File | Purpose |
|------|---------|
| [AGENTS.md](AGENTS.md) | Living context for Cursor agents |
| [PROJECT_REFERENCE.md](PROJECT_REFERENCE.md) | Full reference for other AI systems |

## License

See repository for license details. Not affiliated with Suno, Inc.
