import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/genre_templates.dart';
import '../models/inspiration_dna.dart';
import '../models/song_idea.dart';
import '../providers/generation_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/favorite_picker_field.dart';

class IdeaIntakeScreen extends StatefulWidget {
  const IdeaIntakeScreen({super.key});

  @override
  State<IdeaIntakeScreen> createState() => _IdeaIntakeScreenState();
}

class _IdeaIntakeScreenState extends State<IdeaIntakeScreen> {
  late final TextEditingController _idea;
  late final TextEditingController _constraints;
  late final TextEditingController _vibes;
  late final TextEditingController _title;
  late final TextEditingController _inspArtist;
  late final TextEditingController _inspSong;
  late final TextEditingController _inspLyrics;

  @override
  void initState() {
    super.initState();
    final idea = context.read<GenerationProvider>().idea;
    _idea = TextEditingController(text: idea.rawIdea);
    _constraints = TextEditingController(text: idea.constraints);
    _vibes = TextEditingController(text: idea.referenceVibes);
    _title = TextEditingController(text: idea.titleHint);
    _inspArtist = TextEditingController(text: idea.inspirationArtist);
    _inspSong = TextEditingController(text: idea.inspirationSong);
    _inspLyrics = TextEditingController(text: idea.inspirationLyricsExcerpt);
  }

  @override
  void dispose() {
    _idea.dispose();
    _constraints.dispose();
    _vibes.dispose();
    _title.dispose();
    _inspArtist.dispose();
    _inspSong.dispose();
    _inspLyrics.dispose();
    super.dispose();
  }

  void _sync(GenerationProvider gen, {SongIdea? patch}) {
    final base = patch ?? gen.idea;
    gen.updateIdea(
      base.copyWith(
        rawIdea: _idea.text,
        constraints: _constraints.text,
        referenceVibes: _vibes.text,
        titleHint: _title.text,
        inspirationArtist: _inspArtist.text,
        inspirationSong: _inspSong.text,
        inspirationLyricsExcerpt: _inspLyrics.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gen = context.watch<GenerationProvider>();
    final settings = context.watch<SettingsProvider>();
    final wide = MediaQuery.sizeOf(context).width >= 900;

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
                  'Tagline',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.amber,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Turn a rough song idea into Suno-ready lyrics and a front-loaded style prompt.',
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
                      'Add your NanoGPT API key in Settings before generating.',
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
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _ideaColumn(gen)),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: _sideColumn(gen)),
                    ],
                  )
                : Column(
                    children: [
                      _ideaColumn(gen),
                      const SizedBox(height: 20),
                      _sideColumn(gen),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _ideaColumn(GenerationProvider gen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _idea,
          minLines: 5,
          maxLines: null, // grow with content → page scroll owns gestures
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onChanged: (_) => _sync(gen),
          decoration: const InputDecoration(
            labelText: 'Song idea',
            alignLabelWithHint: true,
            hintText:
                'Theme, mood, story fragments, specific details…\n'
                'e.g. Leaving a small-town apartment at 5am, coffee gone cold, '
                'truck won’t start, pretending you’re fine about it.',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _title,
          onChanged: (_) => _sync(gen),
          decoration: const InputDecoration(
            labelText: 'Title hint (optional)',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _vibes,
          minLines: 1,
          maxLines: null,
          onChanged: (_) => _sync(gen),
          decoration: const InputDecoration(
            labelText: 'Reference vibes (optional)',
            hintText: 'Feel/energy only — never copied lyrics',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _constraints,
          minLines: 2,
          maxLines: null,
          onChanged: (_) => _sync(gen),
          decoration: const InputDecoration(
            labelText: 'Constraints (optional)',
            hintText: 'POV, must-include objects, words to avoid, length…',
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Inspiration DNA',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Optional. Distills an artist / song into an abstract formula '
          '(craft + sonic traits + measured audio when available). '
          'MusicBrainz → tags; Genius → ephemeral lyric patterns; '
          'Deezer → BPM / duration / loudness gain. Each source only '
          'attaches on a real match — misses are fine (partial DNA). '
          'Fetched lyrics are never copied into your output. Your song '
          'idea below steers the new song on top of this baseline.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.35),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _inspArtist,
          onChanged: (_) => _sync(gen),
          decoration: const InputDecoration(
            labelText: 'Artist / group (optional)',
            hintText: 'e.g. a vocalist or band whose vibe you admire',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _inspSong,
          onChanged: (_) => _sync(gen),
          decoration: const InputDecoration(
            labelText: 'Song title (optional)',
            hintText: 'Helps narrow the DNA — still not a cover',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _inspLyrics,
          minLines: 3,
          maxLines: null,
          onChanged: (_) => _sync(gen),
          decoration: const InputDecoration(
            labelText: 'Lyrics excerpt you own/paste (optional)',
            alignLabelWithHint: true,
            hintText:
                'Paste a short excerpt only if you have the right to use it for '
                'private analysis. Tagline extracts patterns — it will not reuse lines.',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: gen.busy
                  ? null
                  : () {
                      _sync(gen);
                      gen.extractInspirationDna();
                    },
              icon: const Icon(Icons.biotech_outlined, size: 18),
              label: const Text('Extract DNA'),
            ),
            const SizedBox(width: 10),
            if (gen.idea.inspirationDnaIsFresh)
              const Icon(Icons.check_circle, color: AppColors.mint, size: 18),
            if (gen.idea.inspirationDnaIsFresh)
              const SizedBox(width: 6),
            if (gen.idea.inspirationDnaIsFresh)
              const Expanded(
                child: Text(
                  'DNA ready — will feed Generate',
                  style: TextStyle(color: AppColors.mint, fontSize: 12.5),
                ),
              ),
          ],
        ),
        if (gen.idea.inspirationDna != null &&
            !gen.idea.inspirationDna!.isEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inkElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gen.idea.inspirationDnaIsFresh
                      ? 'DNA summary'
                      : 'DNA summary (stale — re-extract or Generate will refresh)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  gen.idea.inspirationDna!.summary.isEmpty
                      ? gen.idea.inspirationDna!.styleSeedHints
                      : gen.idea.inspirationDna!.summary,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                if (gen.idea.inspirationDna!.sources.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Sources: ${gen.idea.inspirationDna!.sources.join(', ')}'
                    '${gen.idea.inspirationDna!.geniusTitle.trim().isEmpty ? '' : ' · ${gen.idea.inspirationDna!.geniusTitle.trim()}'}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
                if (gen.idea.inspirationDna!.audioProfile != null &&
                    !gen.idea.inspirationDna!.audioProfile!.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _audioProfileLine(gen.idea.inspirationDna!.audioProfile!),
                    style: const TextStyle(
                      color: AppColors.mint,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                if (gen.idea.inspirationDna!.avoidCopying.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Avoid: ${gen.idea.inspirationDna!.avoidCopying.take(4).join(' · ')}',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: gen.busy
              ? null
              : () {
                  _sync(gen);
                  gen.generate();
                },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate Suno-ready output'),
        ),
      ],
    );
  }

  Widget _sideColumn(GenerationProvider gen) {
    final settings = context.watch<SettingsProvider>();
    final favGenres = settings.favoriteGenreIds.toSet();
    final favMoods = settings.favoriteMoods.toSet();
    final orderedGenres = genresOrdered(favoriteIds: favGenres);
    final orderedMoods = moodsOrdered(favoriteMoods: favMoods);
    final genreLabel = gen.idea.genre?.label ?? '';
    final moodLabel = gen.idea.moods.isEmpty
        ? ''
        : gen.idea.moods.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FavoritePickerField(
          label: 'Genre template',
          hint: 'None — pick a genre',
          valueText: genreLabel,
          onOpen: () => _openGenrePicker(gen, settings, orderedGenres),
        ),
        const SizedBox(height: 6),
        const Text(
          'Loads syllable targets and a style seed. Star favorites to pin them at the top.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
        if (gen.idea.genre != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inkElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              'Verse ${gen.idea.genre!.verseSyllables} · '
              'Chorus ${gen.idea.genre!.chorusSyllables}\n'
              '${gen.idea.genre!.structureHint}',
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FavoritePickerField(
          label: 'Mood',
          hint: 'None — pick one or more',
          valueText: moodLabel,
          onOpen: () => _openMoodPicker(gen, settings, orderedMoods),
        ),
        const SizedBox(height: 6),
        const Text(
          'Multi-select. Favorites stay pinned at the top of the list (A–Z within).',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
      ],
    );
  }

  Future<void> _openGenrePicker(
    GenerationProvider gen,
    SettingsProvider settings,
    List<GenreTemplate> ordered,
  ) async {
    const noneId = '__none__';
    final picked = await showFavoritePickerSheet<String>(
      context: context,
      title: 'Genre',
      subtitle: '${ordered.length} templates · star to pin favorites',
      multiSelect: false,
      noneId: noneId,
      noneLabel: 'None',
      selectedIds: {
        if (gen.idea.genreId != null) gen.idea.genreId!,
      },
      items: [
        for (final g in ordered)
          FavoritePickerItem(
            id: g.id,
            label: g.label,
            isFavorite: settings.isFavoriteGenre(g.id),
          ),
      ],
      onToggleFavorite: settings.toggleFavoriteGenre,
    );
    if (!mounted || picked == null) return;
    if (picked == noneId) {
      _sync(gen, patch: gen.idea.copyWith(clearGenre: true));
    } else {
      _sync(gen, patch: gen.idea.copyWith(genreId: picked));
    }
  }

  String _audioProfileLine(AudioProfile audio) {
    final parts = <String>['Audio (${audio.source})'];
    if (audio.hasBpm) parts.add('${audio.bpmLabel} BPM');
    if (audio.durationSec != null && audio.durationSec! > 0) {
      final m = audio.durationSec! ~/ 60;
      final s = audio.durationSec! % 60;
      parts.add('$m:${s.toString().padLeft(2, '0')}');
    }
    if (audio.gainDb != null) {
      parts.add('gain ${audio.gainDb!.toStringAsFixed(1)} dB');
    }
    if (audio.trackTitle.isNotEmpty) {
      final who = audio.trackArtist.isEmpty
          ? audio.trackTitle
          : '${audio.trackArtist} — ${audio.trackTitle}';
      parts.add(who);
    }
    return parts.join(' · ');
  }

  Future<void> _openMoodPicker(
    GenerationProvider gen,
    SettingsProvider settings,
    List<String> ordered,
  ) async {
    final picked = await showFavoritePickerSheet<Set<String>>(
      context: context,
      title: 'Mood',
      subtitle: '${ordered.length} moods · multi-select · star to pin',
      multiSelect: true,
      selectedIds: gen.idea.moods.toSet(),
      items: [
        for (final m in ordered)
          FavoritePickerItem(
            id: m,
            label: m,
            isFavorite: settings.isFavoriteMood(m),
          ),
      ],
      onToggleFavorite: settings.toggleFavoriteMood,
    );
    if (!mounted || picked == null) return;
    final moods = picked.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _sync(gen, patch: gen.idea.copyWith(moods: moods));
  }
}
