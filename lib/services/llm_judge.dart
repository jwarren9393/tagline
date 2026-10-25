import '../models/generation_result.dart';
import '../prompts/system_prompts.dart';
import 'nanogpt_client.dart';

/// Optional LLM second opinion against the same craft + Suno rubric.
class LlmJudge {
  LlmJudge(this._client);

  final NanoGptClient _client;

  Future<LlmJudgeResult> judge({
    required GenerationResult result,
    required String localEvalLabel,
  }) async {
    final raw = await _client.chat(
      system: SystemPrompts.llmJudgeSystem(),
      user: '''
LOCAL EVAL: $localEvalLabel

STYLE:
${result.stylePrompt}

EXCLUDE:
${result.excludeStyles}

LYRICS:
${result.lyrics}
''',
      temperature: 0.3,
    );

    try {
      final map = extractJsonObject(raw);
      return LlmJudgeResult(
        score: (map['score'] as num?)?.round() ?? 0,
        maxScore: (map['max_score'] as num?)?.round() ?? 100,
        summary: (map['summary'] as String?)?.trim() ?? raw.trim(),
        strengths: _stringList(map['strengths']),
        fixes: _stringList(map['fixes']),
      );
    } catch (_) {
      return LlmJudgeResult(
        score: 0,
        maxScore: 100,
        summary: raw.trim(),
        strengths: const [],
        fixes: const [],
      );
    }
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
}

class LlmJudgeResult {
  const LlmJudgeResult({
    required this.score,
    required this.maxScore,
    required this.summary,
    required this.strengths,
    required this.fixes,
  });

  final int score;
  final int maxScore;
  final String summary;
  final List<String> strengths;
  final List<String> fixes;

  String get label {
    final pct = maxScore == 0 ? 0 : ((score / maxScore) * 100).round();
    return 'LLM judge $pct%';
  }

  String toDisplayNotes() {
    final buf = StringBuffer()
      ..writeln(label)
      ..writeln(summary);
    if (strengths.isNotEmpty) {
      buf.writeln('Strengths: ${strengths.join('; ')}');
    }
    if (fixes.isNotEmpty) {
      buf.writeln('Fixes: ${fixes.join('; ')}');
    }
    return buf.toString().trim();
  }
}
