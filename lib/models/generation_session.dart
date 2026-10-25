import 'generation_result.dart';
import 'song_idea.dart';

/// A persisted generation (idea + outputs + optional quality score).
class GenerationSession {
  GenerationSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.idea,
    required this.result,
    this.evalSummary,
    this.pinned = false,
  });

  final String id;
  final DateTime createdAt;
  DateTime updatedAt;
  SongIdea idea;
  GenerationResult result;
  EvalSummary? evalSummary;
  bool pinned;

  String get displayTitle {
    final t = result.title.trim();
    if (t.isNotEmpty) return t;
    final ideaLine = idea.rawIdea.trim().split('\n').first;
    if (ideaLine.length <= 48) return ideaLine;
    return '${ideaLine.substring(0, 45)}…';
  }

  String get preview => result.lyrics
      .split('\n')
      .where((l) => l.trim().isNotEmpty && !l.trim().startsWith('['))
      .take(2)
      .join(' · ');

  GenerationSession copyWith({
    DateTime? updatedAt,
    SongIdea? idea,
    GenerationResult? result,
    EvalSummary? evalSummary,
    bool? pinned,
    bool clearEval = false,
  }) {
    return GenerationSession(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      idea: idea ?? this.idea,
      result: result ?? this.result,
      evalSummary: clearEval ? null : (evalSummary ?? this.evalSummary),
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'idea': idea.toJson(),
        'result': result.toJson(),
        'evalSummary': evalSummary?.toJson(),
        'pinned': pinned,
      };

  factory GenerationSession.fromJson(Map<String, dynamic> json) {
    return GenerationSession(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      idea: SongIdea.fromJson(json['idea'] as Map<String, dynamic>),
      result: GenerationResult.fromJson(json['result'] as Map<String, dynamic>),
      evalSummary: json['evalSummary'] == null
          ? null
          : EvalSummary.fromJson(
              json['evalSummary'] as Map<String, dynamic>,
            ),
      pinned: json['pinned'] as bool? ?? false,
    );
  }
}

/// Compact quality score stored with a session.
class EvalSummary {
  const EvalSummary({
    required this.score,
    required this.maxScore,
    required this.checks,
    this.ranAt,
  });

  final int score;
  final int maxScore;
  final List<EvalCheck> checks;
  final DateTime? ranAt;

  double get ratio => maxScore == 0 ? 0 : score / maxScore;

  String get label {
    final pct = (ratio * 100).round();
    if (pct >= 85) return 'Strong ($pct%)';
    if (pct >= 65) return 'OK ($pct%)';
    return 'Needs work ($pct%)';
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'maxScore': maxScore,
        'checks': checks.map((c) => c.toJson()).toList(),
        'ranAt': ranAt?.toIso8601String(),
      };

  factory EvalSummary.fromJson(Map<String, dynamic> json) {
    return EvalSummary(
      score: json['score'] as int,
      maxScore: json['maxScore'] as int,
      checks: (json['checks'] as List<dynamic>)
          .map((e) => EvalCheck.fromJson(e as Map<String, dynamic>))
          .toList(),
      ranAt: json['ranAt'] == null
          ? null
          : DateTime.tryParse(json['ranAt'] as String),
    );
  }
}

class EvalCheck {
  const EvalCheck({
    required this.id,
    required this.label,
    required this.passed,
    required this.weight,
    this.detail = '',
  });

  final String id;
  final String label;
  final bool passed;
  final int weight;
  final String detail;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'passed': passed,
        'weight': weight,
        'detail': detail,
      };

  factory EvalCheck.fromJson(Map<String, dynamic> json) {
    return EvalCheck(
      id: json['id'] as String,
      label: json['label'] as String,
      passed: json['passed'] as bool,
      weight: json['weight'] as int,
      detail: json['detail'] as String? ?? '',
    );
  }
}
