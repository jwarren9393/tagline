import '../models/generation_result.dart';
import '../models/song_idea.dart';
import '../prompts/system_prompts.dart';
import 'cliche_detector.dart';
import 'nanogpt_client.dart';
import 'syllable_analyzer.dart';

typedef PassProgressCallback = void Function(List<PipelinePass> passes);

/// Multi-pass lyric + style generation for Suno.
class LyricPipeline {
  LyricPipeline(this._client);

  final NanoGptClient _client;

  static List<PipelinePass> initialPasses() => [
        const PipelinePass(
          id: 'scenes',
          label: 'Scene & senses',
          description: 'Extract concrete scenes, objects, and sensory details',
        ),
        const PipelinePass(
          id: 'arc',
          label: 'Story arc',
          description: 'Outline emotional/story arc and section jobs',
        ),
        const PipelinePass(
          id: 'draft',
          label: 'Draft lyrics',
          description: 'Write conversational lyrics with structure tags',
        ),
        const PipelinePass(
          id: 'structure',
          label: 'Structure tags',
          description: 'Normalize Suno section tags and chorus repeats',
        ),
        const PipelinePass(
          id: 'cliche',
          label: 'Anti-cliché pass',
          description: 'Rewrite abstractions into specific imagery',
        ),
        const PipelinePass(
          id: 'optimize',
          label: 'Suno optimize',
          description: 'Final syllable and delivery polish',
        ),
        const PipelinePass(
          id: 'style',
          label: 'Style prompt',
          description: 'Build front-loaded Style + Exclude Styles',
        ),
      ];

  Future<GenerationResult> generate({
    required SongIdea idea,
    PassProgressCallback? onProgress,
  }) async {
    var passes = initialPasses();
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
    final ideaBlock = idea.toPromptBlock();
    final genreSeed = idea.genre?.styleSeed ?? '';
    final excludeSeed = idea.genre?.excludeSeed ?? '';

    final scenesJson = await runPass(
      index: 0,
      system: SystemPrompts.sceneExtractionSystem(),
      user: ideaBlock,
      temperature: 0.8,
    );
    artifacts['scenes'] = scenesJson;

    final arcJson = await runPass(
      index: 1,
      system: SystemPrompts.arcOutlineSystem(),
      user: '$ideaBlock\n\nSCENE BANK:\n$scenesJson',
      temperature: 0.7,
    );
    artifacts['arc'] = arcJson;

    var lyrics = await runPass(
      index: 2,
      system: SystemPrompts.draftLyricsSystem(),
      user: '$ideaBlock\n\nSCENE BANK:\n$scenesJson\n\nARC:\n$arcJson',
      temperature: 0.85,
      stripFences: true,
    );
    artifacts['draft'] = lyrics;

    lyrics = await runPass(
      index: 3,
      system: SystemPrompts.structurePassSystem(),
      user: 'Normalize structure for Suno:\n\n$lyrics',
      temperature: 0.3,
      stripFences: true,
    );
    artifacts['structure'] = lyrics;

    lyrics = await runPass(
      index: 4,
      system: SystemPrompts.clicheRewriteSystem(),
      user: 'Rewrite for specificity:\n\n$lyrics\n\nSCENE BANK:\n$scenesJson',
      temperature: 0.75,
      stripFences: true,
    );
    artifacts['cliche'] = lyrics;

    // Optimize (JSON)
    update(5, passes[5].copyWith(status: PassStatus.running, output: ''));
    var title = '';
    var notes = '';
    try {
      final optimized = await _client.chat(
        system: SystemPrompts.sunoOptimizeSystem(),
        user: 'Optimize for Suno delivery:\n\n$lyrics',
        temperature: 0.5,
        onToken: (accumulated) {
          update(
            5,
            passes[5].copyWith(
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
      update(5, passes[5].copyWith(status: PassStatus.done, output: lyrics));
    } catch (e) {
      update(5, passes[5].copyWith(status: PassStatus.failed, error: '$e'));
      rethrow;
    }

    // Style
    update(6, passes[6].copyWith(status: PassStatus.running, output: ''));
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

FINAL LYRICS (for mood/energy cues only — do NOT put story in style):
$lyrics
''',
        temperature: 0.6,
        onToken: (accumulated) {
          update(
            6,
            passes[6].copyWith(
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
        6,
        passes[6].copyWith(
          status: PassStatus.done,
          output: 'Style:\n$style\n\nExclude:\n$exclude',
        ),
      );
    } catch (e) {
      update(6, passes[6].copyWith(status: PassStatus.failed, error: '$e'));
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
        id: 'structure_$branchLabel',
        label: 'Structure $branchLabel',
        description: 'Normalize tags for variant $branchLabel',
      ),
      PipelinePass(
        id: 'cliche_$branchLabel',
        label: 'Anti-cliché $branchLabel',
        description: 'Specificity rewrite for variant $branchLabel',
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
      system: SystemPrompts.structurePassSystem(),
      user: 'Normalize structure for Suno:\n\n$lyrics',
      temperature: 0.3,
      stripFences: true,
    );
    lyrics = await runPass(
      index: 2,
      system: SystemPrompts.clicheRewriteSystem(),
      user: 'Rewrite for specificity:\n\n$lyrics\n\nSCENE BANK:\n$scenesJson',
      temperature: 0.75,
      stripFences: true,
    );

    var title = '';
    var notes = '';
    update(3, passes[3].copyWith(status: PassStatus.running, output: ''));
    try {
      final optimized = await _client.chat(
        system: SystemPrompts.sunoOptimizeSystem(),
        user: 'Optimize for Suno delivery:\n\n$lyrics',
        temperature: 0.5,
        onToken: (accumulated) {
          update(
            3,
            passes[3].copyWith(status: PassStatus.running, output: accumulated),
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
      update(3, passes[3].copyWith(status: PassStatus.done, output: lyrics));
    } catch (e) {
      update(3, passes[3].copyWith(status: PassStatus.failed, error: '$e'));
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
