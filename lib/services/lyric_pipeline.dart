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
      onProgress?.call(passes);
    }

    final artifacts = <String, String>{};
    final ideaBlock = idea.toPromptBlock();
    final genreSeed = idea.genre?.styleSeed ?? '';
    final excludeSeed = idea.genre?.excludeSeed ?? '';

    // Pass 1 — scenes
    update(0, passes[0].copyWith(status: PassStatus.running));
    late final String scenesJson;
    try {
      scenesJson = await _client.chat(
        system: SystemPrompts.sceneExtractionSystem(),
        user: ideaBlock,
        temperature: 0.8,
      );
      artifacts['scenes'] = scenesJson;
      update(0, passes[0].copyWith(status: PassStatus.done, output: scenesJson));
    } catch (e) {
      update(0, passes[0].copyWith(status: PassStatus.failed, error: '$e'));
      rethrow;
    }

    // Pass 2 — arc
    update(1, passes[1].copyWith(status: PassStatus.running));
    late final String arcJson;
    try {
      arcJson = await _client.chat(
        system: SystemPrompts.arcOutlineSystem(),
        user: '$ideaBlock\n\nSCENE BANK:\n$scenesJson',
        temperature: 0.7,
      );
      artifacts['arc'] = arcJson;
      update(1, passes[1].copyWith(status: PassStatus.done, output: arcJson));
    } catch (e) {
      update(1, passes[1].copyWith(status: PassStatus.failed, error: '$e'));
      rethrow;
    }

    // Pass 3 — draft
    update(2, passes[2].copyWith(status: PassStatus.running));
    late String lyrics;
    try {
      lyrics = await _client.chat(
        system: SystemPrompts.draftLyricsSystem(),
        user: '$ideaBlock\n\nSCENE BANK:\n$scenesJson\n\nARC:\n$arcJson',
        temperature: 0.85,
      );
      lyrics = _stripFences(lyrics);
      artifacts['draft'] = lyrics;
      update(2, passes[2].copyWith(status: PassStatus.done, output: lyrics));
    } catch (e) {
      update(2, passes[2].copyWith(status: PassStatus.failed, error: '$e'));
      rethrow;
    }

    // Pass 4 — structure
    update(3, passes[3].copyWith(status: PassStatus.running));
    try {
      lyrics = await _client.chat(
        system: SystemPrompts.structurePassSystem(),
        user: 'Normalize structure for Suno:\n\n$lyrics',
        temperature: 0.3,
      );
      lyrics = _stripFences(lyrics);
      artifacts['structure'] = lyrics;
      update(3, passes[3].copyWith(status: PassStatus.done, output: lyrics));
    } catch (e) {
      update(3, passes[3].copyWith(status: PassStatus.failed, error: '$e'));
      rethrow;
    }

    // Pass 5 — cliché rewrite
    update(4, passes[4].copyWith(status: PassStatus.running));
    try {
      lyrics = await _client.chat(
        system: SystemPrompts.clicheRewriteSystem(),
        user: 'Rewrite for specificity:\n\n$lyrics\n\nSCENE BANK:\n$scenesJson',
        temperature: 0.75,
      );
      lyrics = _stripFences(lyrics);
      artifacts['cliche'] = lyrics;
      update(4, passes[4].copyWith(status: PassStatus.done, output: lyrics));
    } catch (e) {
      update(4, passes[4].copyWith(status: PassStatus.failed, error: '$e'));
      rethrow;
    }

    // Pass 6 — optimize (JSON)
    update(5, passes[5].copyWith(status: PassStatus.running));
    var title = '';
    var notes = '';
    try {
      final optimized = await _client.chat(
        system: SystemPrompts.sunoOptimizeSystem(),
        user: 'Optimize for Suno delivery:\n\n$lyrics',
        temperature: 0.5,
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

    // Pass 7 — style (can use genre seed)
    update(6, passes[6].copyWith(status: PassStatus.running));
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
      // Style failure is non-fatal if we have a genre seed
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

  Future<String> makeMoreSpecific(String lyrics) async {
    final out = await _client.chat(
      system: SystemPrompts.makeMoreSpecificSystem(),
      user: lyrics,
      temperature: 0.75,
    );
    return _stripFences(out);
  }

  Future<String> regenerateSection({
    required String lyrics,
    required String sectionTag,
  }) async {
    final out = await _client.chat(
      system: SystemPrompts.regenerateSectionSystem(sectionTag),
      user: lyrics,
      temperature: 0.8,
    );
    return _stripFences(out);
  }

  Future<String> refineChat({
    required String historyContext,
    required String userMessage,
  }) async {
    return _client.chat(
      system: SystemPrompts.refinementChatSystem(),
      user: '$historyContext\n\nUSER: $userMessage',
      temperature: 0.7,
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
