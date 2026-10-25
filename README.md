# Tagline

**Expert pre-production tool for [Suno AI](https://suno.com)** (Premier / Studio).

Tagline turns a rough song idea — theme, mood, story fragments, genre preference, reference vibes — into high-quality **Suno-ready lyrics** and a clean, front-loaded **Style prompt** (plus Exclude Styles). Paste the outputs into Custom Mode / Studio and get better first-generation results with less generate–wait–rewrite.

## Who it’s for

Songwriters and producers who use Suno and want lyrics that actually sing: concrete imagery, conversational language, consistent syllable counts, and proper structure tags — not AI cheese.

## Key features

- **Multi-pass generation** (not one-shot): scene/sensory extraction → story arc → draft → structure tags → anti-cliché rewrite → Suno optimize → style prompt
- **Suno-accurate formatting**: section tags on their own lines; Style = sound only; negatives in Exclude Styles
- **Anti-cliché craft**: constrained cliché families, show-don’t-tell prompting (Pat Pattison–inspired), local cliché/syllable feedback
- **Genre templates** with style seeds and syllable targets
- **Tools**: Make more specific, regenerate a section, refinement chat, copy buttons
- **Secure NanoGPT API key** storage (`flutter_secure_storage`)

## Platforms

Native Flutter app for **Windows**, **Linux**, and **Android**. No web build required.

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
5. Use **Make more specific**, section regenerate, or the refine chat to iterate without starting over.

## Project docs

| File | Purpose |
|------|---------|
| [AGENTS.md](AGENTS.md) | Living context for Cursor agents |
| [PROJECT_REFERENCE.md](PROJECT_REFERENCE.md) | Full reference for other AI systems |

## License

See repository for license details. Not affiliated with Suno, Inc.
