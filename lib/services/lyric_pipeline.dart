import '../models/generation_result.dart';
import '../models/inspiration_dna.dart';
import '../models/lyric_rescue_input.dart';
import '../models/song_idea.dart';
import '../prompts/system_prompts.dart';
import 'cliche_detector.dart';
import 'inspiration_dna_service.dart';
import 'nanogpt_client.dart';
import 'syllable_analyzer.dart';

typedef PassProgressCallback = void Function(List<PipelinePass> passes);

/// Multi-pass lyric + style generation for Suno.
class LyricPipeline {
  LyricPipeline(this._client) : _inspiration = InspirationDnaService(_client);

  final NanoGptClient _client;
  final InspirationDnaService _inspiration;

  static List<PipelinePass> initialPasses({bool withInspiration = false}) => [
        if (withInspiration)
          const PipelinePass(
            id: 'inspiration',
            label: 'Inspiration DNA',
            description: 'Abstract sonic + craft formula (never a copy)',
          ),
        const PipelinePass(
          id: 'scenes',
          label: 'Voice & brief',
          description: 'Extract voice, conflict, and a few optional details',
        ),
        const PipelinePass(
          id: 'arc',
          label: 'Story arc',
          description: 'Outline emotional/story arc and section jobs',
        ),
        const PipelinePass(
          id: 'draft',
          label: 'Draft lyrics',
          description: 'Write singable lyrics with rhyme + structure tags',
        ),
        const PipelinePass(
          id: 'cliche',
          label: 'Anti-slop pass',
          description: 'Kill pastiche; keep voice, rhyme, and substance',
        ),
        const PipelinePass(
          id: 'optimize',
          label: 'Suno optimize',
          description: 'Final meter, rhyme, and delivery polish',
        ),
        const PipelinePass(
          id: 'style',
          label: 'Style prompt',
          description: 'Build front-loaded Style + Exclude Styles',
        ),
      ];

  static List<PipelinePass> initialRescuePasses() => const [
        PipelinePass(
          id: 'diagnose',
          label: 'Diagnose',
          description: 'Find slop and what is worth keeping',
        ),
        PipelinePass(
          id: 'rewrite',
          label: 'Rescue rewrite',
          description: 'Keep soul + structure; apply Tagline craft',
        ),
        PipelinePass(
          id: 'cliche',
          label: 'Anti-slop pass',
          description: 'Kill leftover pastiche; keep voice and rhyme',
        ),
        PipelinePass(
          id: 'optimize',
          label: 'Suno optimize',
          description: 'Final meter, rhyme, and delivery polish',
        ),
        PipelinePass(
          id: 'style',
          label: 'Style remaster',
          description: 'Polish Style/Exclude for remix or cover paste-back',
        ),
      ];

  Future<GenerationResult> generate({
    required SongIdea idea,
    PassProgressCallback? onProgress,
  }) async {
    final withInspiration = idea.hasInspirationSource;
    var passes = initialPasses(withInspiration: withInspiration);
    void update(int index, PipelinePass pass) {
      passes = List<PipelinePass>.from(passes)..[index] = pass;
      onProgress?.call(List.unmodifiable(passes));
    }

    Future<String> runPass({
      required int index,
      required String system,
      required String user,
      required double temperature,
      bool stripFences = false,
    }) async {
      update(index, passes[index].copyWith(status: PassStatus.running, output: ''));
      try {
        final raw = await _client.chat(
          system: system,
          user: user,
          temperature: temperature,
          onToken: (accumulated) {
            update(
              index,
              passes[index].copyWith(
                status: PassStatus.running,
                output: accumulated,
              ),
            );
          },
        );
        final text = stripFences ? _stripFences(raw) : raw;
        update(
          index,
          passes[index].copyWith(status: PassStatus.done, output: text),
        );
        return text;
      } catch (e) {
        update(
          index,
          passes[index].copyWith(status: PassStatus.failed, error: '$e'),
        );
        rethrow;
      }
    }

    final artifacts = <String, String>{};
    var workingIdea = idea;
    var index = 0;

    if (withInspiration) {
      update(index, passes[index].copyWith(status: PassStatus.running, output: ''));
      try {
        InspirationDna dna;
        if (idea.inspirationDnaIsFresh) {
          dna = idea.inspirationDna!;
          update(
            index,
            passes[index].copyWith(
              status: PassStatus.done,
              output: dna.summary.isEmpty ? dna.encodePretty() : dna.summary,
            ),
          );
        } else {
          dna = await _inspiration.extract(
            artist: idea.inspirationArtist,
            song: idea.inspirationSong,
            lyricsExcerpt: idea.inspirationLyricsExcerpt,
            onToken: (accumulated) {
              update(
                index,
                passes[index].copyWith(
                  status: PassStatus.running,
                  output: accumulated,
                ),
              );
            },
          );
          update(
            index,
            passes[index].copyWith(
              status: PassStatus.done,
              output: dna.summary.isEmpty ? dna.encodePretty() : dna.summary,
            ),
          );
        }
        workingIdea = idea.copyWith(inspirationDna: dna);
        artifacts['inspiration'] = dna.encodePretty();
      } catch (e) {
        update(
          index,
          passes[index].copyWith(status: PassStatus.failed, error: '$e'),
        );
        rethrow;
      }
      index++;
    }

    final ideaBlock = workingIdea.toPromptBlock();
    var genreSeed = workingIdea.genre?.styleSeed ?? '';
    final excludeSeed = workingIdea.genre?.excludeSeed ?? '';
    final dna = workingIdea.inspirationDna;
    final audio = dna?.audioProfile;
    if (audio != null && audio.hasBpm) {
      final bpmBit = '${audio.bpmLabel} BPM';
      genreSeed = genreSeed.isEmpty ? bpmBit : '$bpmBit, $genreSeed';
    }
    final dnaHints = dna?.styleSeedHints.trim() ?? '';
    if (dnaHints.isNotEmpty) {
      genreSeed = genreSeed.isEmpty ? dnaHints : '$genreSeed, $dnaHints';
    }

    final scenesJson = await runPass(
      index: index,
      system: SystemPrompts.sceneExtractionSystem(),
      user: ideaBlock,
      temperature: 0.8,
    );
    artifacts['scenes'] = scenesJson;
    index++;

    final arcJson = await runPass(
      index: index,
      system: SystemPrompts.arcOutlineSystem(),
      user: '$ideaBlock\n\nSCENE BANK:\n$scenesJson',
      temperature: 0.7,
    );
    artifacts['arc'] = arcJson;
    index++;

    var lyrics = await runPass(
      index: index,
      system: SystemPrompts.draftLyricsSystem(),
      user: '$ideaBlock\n\nSCENE BANK:\n$scenesJson\n\nARC:\n$arcJson',
      temperature: 0.85,
      stripFences: true,
    );
    artifacts['draft'] = lyrics;
    index++;

    lyrics = await runPass(
      index: index,
      system: SystemPrompts.clicheRewriteSystem(),
      user:
          'Rewrite for voice, rhyme, and anti-slop:\n\n$lyrics\n\nSCENE BANK:\n$scenesJson',
      temperature: 0.75,
      stripFences: true,
    );
    artifacts['cliche'] = lyrics;
    index++;

    // Optimize (JSON) — also owns structure/chorus normalization now.
    final optimizeIndex = index;
    update(
      optimizeIndex,
      passes[optimizeIndex].copyWith(status: PassStatus.running, output: ''),
    );
    var title = '';
    var notes = '';
    try {
      final optimized = await _client.chat(
        system: SystemPrompts.sunoOptimizeSystem(),
        user: 'Optimize for Suno delivery:\n\n$lyrics',
        temperature: 0.5,
        onToken: (accumulated) {
          update(
            optimizeIndex,
            passes[optimizeIndex].copyWith(
              status: PassStatus.running,
              output: accumulated,
            ),
          );
        },
      );
      artifacts['optimize_raw'] = optimized;
      try {
        final map = extractJsonObject(optimized);
        lyrics = (map['lyrics'] as String?)?.trim().isNotEmpty == true
            ? map['lyrics'] as String
            : lyrics;
        title = (map['title'] as String?)?.trim() ?? '';
        notes = (map['notes'] as String?)?.trim() ?? '';
      } catch (_) {
        lyrics = _stripFences(optimized);
      }
      update(
        optimizeIndex,
        passes[optimizeIndex].copyWith(status: PassStatus.done, output: lyrics),
      );
    } catch (e) {
      update(
        optimizeIndex,
        passes[optimizeIndex].copyWith(status: PassStatus.failed, error: '$e'),
      );
      rethrow;
    }
    index++;

    // Style
    final styleIndex = index;
    update(
      styleIndex,
      passes[styleIndex].copyWith(status: PassStatus.running, output: ''),
    );
    var style = genreSeed;
    var exclude = excludeSeed;
    try {
      final styleRaw = await _client.chat(
        system: SystemPrompts.stylePromptSystem(),
        user: '''
Build Style + Exclude Styles for this song.

$ideaBlock

GENRE STYLE SEED (refine, do not ignore genre-first ordering):
$genreSeed

EXCLUDE SEED:
$excludeSeed

FINAL LYRICS (for mood/energy cues only — do NOT put story or section tags in style):
$lyrics
''',
        temperature: 0.6,
        onToken: (accumulated) {
          update(
            styleIndex,
            passes[styleIndex].copyWith(
              status: PassStatus.running,
              output: accumulated,
            ),
          );
        },
      );
      artifacts['style_raw'] = styleRaw;
      try {
        final map = extractJsonObject(styleRaw);
        style = (map['style'] as String?)?.trim().isNotEmpty == true
            ? map['style'] as String
            : style;
        exclude = (map['exclude_styles'] as String?)?.trim().isNotEmpty == true
            ? map['exclude_styles'] as String
            : exclude;
      } catch (_) {
        if (styleRaw.trim().isNotEmpty) style = styleRaw.trim();
      }
      style = _truncate(style, 900);
      exclude = _truncate(exclude, 900);
      update(
        styleIndex,
        passes[styleIndex].copyWith(
          status: PassStatus.done,
          output: 'Style:\n$style\n\nExclude:\n$exclude',
        ),
      );
    } catch (e) {
      update(
        styleIndex,
        passes[styleIndex].copyWith(status: PassStatus.failed, error: '$e'),
      );
      if (style.isEmpty) rethrow;
    }

    return GenerationResult(
      lyrics: lyrics.trim(),
      stylePrompt: style.trim(),
      excludeStyles: exclude.trim(),
      title: title,
      notes: notes,
      passArtifacts: artifacts,
    );
  }

  /// Remaster existing Suno (or other) lyrics with Tagline craft rules.
  Future<GenerationResult> rescue({
    required LyricRescueInput input,
    PassProgressCallback? onProgress,
  }) async {
    if (!input.isValid) {
      throw ArgumentError(
        'Paste at least a short block of lyrics to rescue (40+ chars).',
      );
    }

    var passes = initialRescuePasses();
    void update(int index, PipelinePass pass) {
      passes = List<PipelinePass>.from(passes)..[index] = pass;
      onProgress?.call(List.unmodifiable(passes));
    }

    Future<String> runPass({
      required int index,
      required String system,
      required String user,
      required double temperature,
      bool stripFences = false,
    }) async {
      update(index, passes[index].copyWith(status: PassStatus.running, output: ''));
      try {
        final raw = await _client.chat(
          system: system,
          user: user,
          temperature: temperature,
          onToken: (accumulated) {
            update(
              index,
              passes[index].copyWith(
                status: PassStatus.running,
                output: accumulated,
              ),
            );
          },
        );
        final text = stripFences ? _stripFences(raw) : raw;
        update(
          index,
          passes[index].copyWith(status: PassStatus.done, output: text),
        );
        return text;
      } catch (e) {
        update(
          index,
          passes[index].copyWith(status: PassStatus.failed, error: '$e'),
        );
        rethrow;
      }
    }

    final artifacts = <String, String>{};
    final block = input.toPromptBlock();
    var index = 0;

    final diagnoseRaw = await runPass(
      index: index,
      system: SystemPrompts.rescueDiagnoseSystem(),
      user: block,
      temperature: 0.4,
    );
    artifacts['diagnose'] = diagnoseRaw;
    var keepHints = '';
    var fixHints = '';
    try {
      final map = extractJsonObject(diagnoseRaw);
      final keep = map['keep'];
      final fix = map['fix'];
      if (keep is List) {
        keepHints = keep.map((e) => '$e').where((e) => e.trim().isNotEmpty).join('; ');
      }
      if (fix is List) {
        fixHints = fix.map((e) => '$e').where((e) => e.trim().isNotEmpty).join('; ');
      }
      final summary = '${map['summary'] ?? ''}'.trim();
      if (summary.isNotEmpty) artifacts['diagnose_summary'] = summary;
    } catch (_) {}
    index++;

    var lyrics = await runPass(
      index: index,
      system: SystemPrompts.rescueRewriteSystem(),
      user: '''
$block

DIAGNOSIS (honor KEEP; fix FIX):
$diagnoseRaw

KEEP HINTS: ${keepHints.isEmpty ? '(none parsed)' : keepHints}
FIX HINTS: ${fixHints.isEmpty ? '(none parsed)' : fixHints}

Rewrite the full lyrics now.
''',
      temperature: 0.75,
      stripFences: true,
    );
    artifacts['rewrite'] = lyrics;
    index++;

    lyrics = await runPass(
      index: index,
      system: SystemPrompts.clicheRewriteSystem(),
      user: '''
Anti-slop polish for a RESCUED song (keep identity + creator intent):

CREATOR NOTES: ${input.creatorNotes.trim().isEmpty ? '(none)' : input.creatorNotes.trim()}

CURRENT LYRICS:
$lyrics
''',
      temperature: 0.7,
      stripFences: true,
    );
    artifacts['cliche'] = lyrics;
    index++;

    final optimizeIndex = index;
    update(
      optimizeIndex,
      passes[optimizeIndex].copyWith(status: PassStatus.running, output: ''),
    );
    var title = input.title.trim();
    var notes = '';
    try {
      final optimized = await _client.chat(
        system: SystemPrompts.sunoOptimizeSystem(),
        user: 'Optimize rescued lyrics for Suno delivery:\n\n$lyrics',
        temperature: 0.5,
        onToken: (accumulated) {
          update(
            optimizeIndex,
            passes[optimizeIndex].copyWith(
              status: PassStatus.running,
              output: accumulated,
            ),
          );
        },
      );
      artifacts['optimize_raw'] = optimized;
      try {
        final map = extractJsonObject(optimized);
        lyrics = (map['lyrics'] as String?)?.trim().isNotEmpty == true
            ? map['lyrics'] as String
            : lyrics;
        final t = (map['title'] as String?)?.trim() ?? '';
        if (t.isNotEmpty) title = t;
        notes = (map['notes'] as String?)?.trim() ?? '';
      } catch (_) {
        lyrics = _stripFences(optimized);
      }
      update(
        optimizeIndex,
        passes[optimizeIndex].copyWith(status: PassStatus.done, output: lyrics),
      );
    } catch (e) {
      update(
        optimizeIndex,
        passes[optimizeIndex].copyWith(status: PassStatus.failed, error: '$e'),
      );
      rethrow;
    }
    index++;

    final styleIndex = index;
    update(
      styleIndex,
      passes[styleIndex].copyWith(status: PassStatus.running, output: ''),
    );
    var style = input.stylePrompt.trim();
    var exclude = input.excludeStyles.trim();
    try {
      final styleRaw = await _client.chat(
        system: SystemPrompts.rescueStyleSystem(),
        user: '''
Remaster Style + Exclude for paste-back into Suno (remix / cover / reuse).

$block

RESCUED LYRICS (energy cues only — do not put story in Style):
$lyrics
''',
        temperature: 0.55,
        onToken: (accumulated) {
          update(
            styleIndex,
            passes[styleIndex].copyWith(
              status: PassStatus.running,
              output: accumulated,
            ),
          );
        },
      );
      artifacts['style_raw'] = styleRaw;
      try {
        final map = extractJsonObject(styleRaw);
        style = (map['style'] as String?)?.trim().isNotEmpty == true
            ? map['style'] as String
            : style;
        exclude = (map['exclude_styles'] as String?)?.trim().isNotEmpty == true
            ? map['exclude_styles'] as String
            : exclude;
      } catch (_) {
        if (styleRaw.trim().isNotEmpty && style.isEmpty) {
          style = styleRaw.trim();
        }
      }
      style = _truncate(style, 900);
      exclude = _truncate(exclude, 900);
      update(
        styleIndex,
        passes[styleIndex].copyWith(
          status: PassStatus.done,
          output: 'Style:\n$style\n\nExclude:\n$exclude',
        ),
      );
    } catch (e) {
      update(
        styleIndex,
        passes[styleIndex].copyWith(status: PassStatus.failed, error: '$e'),
      );
      if (style.isEmpty) rethrow;
    }

    if (notes.isEmpty) {
      notes =
          'Rescued lyrics — paste into Suno as a remix/cover/reuse with the remastered Style.';
    }

    return GenerationResult(
      lyrics: lyrics.trim(),
      stylePrompt: style.trim(),
      excludeStyles: exclude.trim(),
      title: title,
      notes: notes,
      passArtifacts: artifacts,
    );
  }

  Future<InspirationDna> extractInspirationDna({
    required String artist,
    required String song,
    required String lyricsExcerpt,
    TokenCallback? onToken,
  }) {
    return _inspiration.extract(
      artist: artist,
      song: song,
      lyricsExcerpt: lyricsExcerpt,
      onToken: onToken,
    );
  }

  /// Continue from existing scene/arc artifacts with a draft-system variant.
  /// Used for A/B experiments without re-paying for scene extraction.
  Future<GenerationResult> generateLyricBranch({
    required SongIdea idea,
    required String scenesJson,
    required String arcJson,
    required String draftSystem,
    String branchLabel = 'B',
    PassProgressCallback? onProgress,
  }) async {
    var passes = [
      PipelinePass(
        id: 'draft_$branchLabel',
        label: 'Draft $branchLabel',
        description: 'Variant $branchLabel lyrics draft',
      ),
      PipelinePass(
        id: 'cliche_$branchLabel',
        label: 'Anti-slop $branchLabel',
        description: 'Voice/rhyme rewrite for variant $branchLabel',
      ),
      PipelinePass(
        id: 'optimize_$branchLabel',
        label: 'Optimize $branchLabel',
        description: 'Suno polish for variant $branchLabel',
      ),
    ];

    void update(int index, PipelinePass pass) {
      passes = List<PipelinePass>.from(passes)..[index] = pass;
      onProgress?.call(List.unmodifiable(passes));
    }

    Future<String> runPass({
      required int index,
      required String system,
      required String user,
      required double temperature,
      bool stripFences = false,
    }) async {
      update(index, passes[index].copyWith(status: PassStatus.running, output: ''));
      try {
        final raw = await _client.chat(
          system: system,
          user: user,
          temperature: temperature,
          onToken: (accumulated) {
            update(
              index,
              passes[index].copyWith(
                status: PassStatus.running,
                output: accumulated,
              ),
            );
          },
        );
        final text = stripFences ? _stripFences(raw) : raw;
        update(
          index,
          passes[index].copyWith(status: PassStatus.done, output: text),
        );
        return text;
      } catch (e) {
        update(
          index,
          passes[index].copyWith(status: PassStatus.failed, error: '$e'),
        );
        rethrow;
      }
    }

    final ideaBlock = idea.toPromptBlock();
    var lyrics = await runPass(
      index: 0,
      system: draftSystem,
      user: '$ideaBlock\n\nSCENE BANK:\n$scenesJson\n\nARC:\n$arcJson',
      temperature: 0.85,
      stripFences: true,
    );
    lyrics = await runPass(
      index: 1,
      system: SystemPrompts.clicheRewriteSystem(),
      user:
          'Rewrite for voice, rhyme, and anti-slop:\n\n$lyrics\n\nSCENE BANK:\n$scenesJson',
      temperature: 0.75,
      stripFences: true,
    );

    var title = '';
    var notes = '';
    update(2, passes[2].copyWith(status: PassStatus.running, output: ''));
    try {
      final optimized = await _client.chat(
        system: SystemPrompts.sunoOptimizeSystem(),
        user: 'Optimize for Suno delivery:\n\n$lyrics',
        temperature: 0.5,
        onToken: (accumulated) {
          update(
            2,
            passes[2].copyWith(status: PassStatus.running, output: accumulated),
          );
        },
      );
      try {
        final map = extractJsonObject(optimized);
        lyrics = (map['lyrics'] as String?)?.trim().isNotEmpty == true
            ? map['lyrics'] as String
            : lyrics;
        title = (map['title'] as String?)?.trim() ?? '';
        notes = (map['notes'] as String?)?.trim() ?? '';
      } catch (_) {
        lyrics = _stripFences(optimized);
      }
      update(2, passes[2].copyWith(status: PassStatus.done, output: lyrics));
    } catch (e) {
      update(2, passes[2].copyWith(status: PassStatus.failed, error: '$e'));
      rethrow;
    }

    return GenerationResult(
      lyrics: lyrics.trim(),
      stylePrompt: '',
      title: title,
      notes: notes,
      passArtifacts: {
        'scenes': scenesJson,
        'arc': arcJson,
        'branch': branchLabel,
      },
    );
  }

  Future<String> makeMoreSpecific(
    String lyrics, {
    TokenCallback? onToken,
  }) async {
    final out = await _client.chat(
      system: SystemPrompts.makeMoreSpecificSystem(),
      user: lyrics,
      temperature: 0.75,
      onToken: onToken,
    );
    return _stripFences(out);
  }

  Future<String> regenerateSection({
    required String lyrics,
    required String sectionTag,
    TokenCallback? onToken,
  }) async {
    final out = await _client.chat(
      system: SystemPrompts.regenerateSectionSystem(sectionTag),
      user: lyrics,
      temperature: 0.8,
      onToken: onToken,
    );
    return _stripFences(out);
  }

  Future<String> refineChat({
    required String historyContext,
    required String userMessage,
    TokenCallback? onToken,
  }) async {
    return _client.chat(
      system: SystemPrompts.refinementChatSystem(),
      user: '$historyContext\n\nUSER: $userMessage',
      temperature: 0.7,
      onToken: onToken,
    );
  }

  LyricFeedback feedbackFor(String lyrics) {
    final syllables = SyllableAnalyzer.analyze(lyrics);
    return ClicheDetector.combineWithSyllables(
      lyrics: lyrics,
      syllableFeedback: syllables,
    );
  }

  static String _stripFences(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      final firstNl = t.indexOf('\n');
      if (firstNl > 0) t = t.substring(firstNl + 1);
      if (t.endsWith('```')) {
        t = t.substring(0, t.length - 3);
      }
    }
    return t.trim();
  }

  static String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return s.substring(0, max).trim();
  }
}
