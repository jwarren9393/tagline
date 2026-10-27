import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lyric_rescue_input.dart';
import '../models/song_idea.dart';
import '../providers/generation_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Paste an existing Suno song and run it through Tagline lyric craft.
class LyricRescueScreen extends StatefulWidget {
  const LyricRescueScreen({super.key});

  @override
  State<LyricRescueScreen> createState() => _LyricRescueScreenState();
}

class _LyricRescueScreenState extends State<LyricRescueScreen> {
  late final TextEditingController _title;
  late final TextEditingController _lyrics;
  late final TextEditingController _style;
  late final TextEditingController _exclude;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final rescue = context.read<GenerationProvider>().idea.rescue ??
        const LyricRescueInput();
    _title = TextEditingController(text: rescue.title);
    _lyrics = TextEditingController(text: rescue.lyrics);
    _style = TextEditingController(text: rescue.stylePrompt);
    _exclude = TextEditingController(text: rescue.excludeStyles);
    _notes = TextEditingController(text: rescue.creatorNotes);
  }

  @override
  void dispose() {
    _title.dispose();
    _lyrics.dispose();
    _style.dispose();
    _exclude.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _sync(GenerationProvider gen) {
    final rescue = LyricRescueInput(
      title: _title.text,
      lyrics: _lyrics.text,
      stylePrompt: _style.text,
      excludeStyles: _exclude.text,
      creatorNotes: _notes.text,
    );
    final notes = _notes.text.trim();
    final title = _title.text.trim();
    gen.updateIdea(
      SongIdea(
        rawIdea: notes.isNotEmpty
            ? notes
            : (title.isNotEmpty ? 'Rescue: $title' : 'Lyric rescue'),
        titleHint: title,
        mode: 'rescue',
        rescue: rescue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gen = context.watch<GenerationProvider>();
    final settings = context.watch<SettingsProvider>();

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lyric Rescue',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.amber,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Paste a song that already sounds good but has weak / AI lyrics. '
                  'Tagline rewrites craft while keeping your intent — then take '
                  'the pack back to Suno for a remix, cover, or reuse.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                ),
                if (!settings.hasApiKey) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Add your NanoGPT API key in Settings before rescuing.',
                      style: TextStyle(color: AppColors.amber),
                    ),
                  ),
                ],
                if (gen.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    gen.error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _title,
                  onChanged: (_) => _sync(gen),
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                    hintText: 'As named in Suno / your library',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your intent / thoughts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'What you meant the song to be about — feelings, story, '
                  'who it’s for. The rewrite will honor this.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notes,
                  onChanged: (_) => _sync(gen),
                  maxLines: null,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. late-night apology that never gets sent; keep the chorus soft',
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Original lyrics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Paste from Suno Lyrics (structure tags welcome). Required.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _lyrics,
                  onChanged: (_) => _sync(gen),
                  maxLines: null,
                  minLines: 10,
                  decoration: const InputDecoration(
                    hintText: '[Verse 1]\n…\n[Chorus]\n…',
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Original Style (optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Suno Style field — kept as sonic baseline for the remaster.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _style,
                  onChanged: (_) => _sync(gen),
                  maxLines: null,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'genre, mood, vocal, instruments, BPM…',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _exclude,
                  onChanged: (_) => _sync(gen),
                  maxLines: null,
                  minLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Exclude Styles (optional)',
                    hintText: 'negatives from Suno Exclude field',
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: gen.busy
                      ? null
                      : () {
                          _sync(gen);
                          gen.rescueLyrics();
                        },
                  icon: const Icon(Icons.healing_outlined),
                  label: const Text('Rescue lyrics'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Output is a Suno-ready pack (lyrics + style). How you remix '
                  'or cover in Suno is up to you — Tagline handles the words.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
