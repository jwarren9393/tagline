import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/genre_templates.dart';
import '../models/song_idea.dart';
import '../providers/generation_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    final idea = context.read<GenerationProvider>().idea;
    _idea = TextEditingController(text: idea.rawIdea);
    _constraints = TextEditingController(text: idea.constraints);
    _vibes = TextEditingController(text: idea.referenceVibes);
    _title = TextEditingController(text: idea.titleHint);
  }

  @override
  void dispose() {
    _idea.dispose();
    _constraints.dispose();
    _vibes.dispose();
    _title.dispose();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Genre template', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'Loads syllable targets and a style seed. You can still edit outputs later.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('None'),
              selected: gen.idea.genreId == null,
              onSelected: (_) {
                _sync(gen, patch: gen.idea.copyWith(clearGenre: true));
              },
            ),
            ...kGenreTemplates.map((g) {
              return FilterChip(
                label: Text(g.label),
                selected: gen.idea.genreId == g.id,
                onSelected: (_) {
                  _sync(gen, patch: gen.idea.copyWith(genreId: g.id));
                },
              );
            }),
          ],
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
        Text('Mood', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kMoodOptions.map((m) {
            final selected = gen.idea.moods.contains(m);
            return FilterChip(
              label: Text(m),
              selected: selected,
              onSelected: (v) {
                final moods = List<String>.from(gen.idea.moods);
                if (v) {
                  moods.add(m);
                } else {
                  moods.remove(m);
                }
                _sync(gen, patch: gen.idea.copyWith(moods: moods));
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
