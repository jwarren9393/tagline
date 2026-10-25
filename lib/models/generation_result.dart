/// Final (or intermediate) outputs ready for Suno Custom Mode / Studio.
class GenerationResult {
  const GenerationResult({
    required this.lyrics,
    required this.stylePrompt,
    this.excludeStyles = '',
    this.title = '',
    this.notes = '',
    this.passArtifacts = const {},
  });

  final String lyrics;
  final String stylePrompt;
  final String excludeStyles;
  final String title;
  final String notes;

  /// Named intermediate pass outputs for debugging / refinement UI.
  final Map<String, String> passArtifacts;

  GenerationResult copyWith({
    String? lyrics,
    String? stylePrompt,
    String? excludeStyles,
    String? title,
    String? notes,
    Map<String, String>? passArtifacts,
  }) {
    return GenerationResult(
      lyrics: lyrics ?? this.lyrics,
      stylePrompt: stylePrompt ?? this.stylePrompt,
      excludeStyles: excludeStyles ?? this.excludeStyles,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      passArtifacts: passArtifacts ?? this.passArtifacts,
    );
  }

  static const empty = GenerationResult(
    lyrics: '',
    stylePrompt: '',
  );

  bool get hasLyrics => lyrics.trim().isNotEmpty;
  bool get hasStyle => stylePrompt.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'lyrics': lyrics,
        'stylePrompt': stylePrompt,
        'excludeStyles': excludeStyles,
        'title': title,
        'notes': notes,
        'passArtifacts': passArtifacts,
      };

  factory GenerationResult.fromJson(Map<String, dynamic> json) {
    final artifactsRaw = json['passArtifacts'];
    final artifacts = <String, String>{};
    if (artifactsRaw is Map) {
      artifactsRaw.forEach((k, v) {
        artifacts[k.toString()] = v?.toString() ?? '';
      });
    }
    return GenerationResult(
      lyrics: json['lyrics'] as String? ?? '',
      stylePrompt: json['stylePrompt'] as String? ?? '',
      excludeStyles: json['excludeStyles'] as String? ?? '',
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      passArtifacts: artifacts,
    );
  }
}

/// Status of a single pipeline pass.
enum PassStatus { pending, running, done, failed, skipped }

class PipelinePass {
  const PipelinePass({
    required this.id,
    required this.label,
    required this.description,
    this.status = PassStatus.pending,
    this.output = '',
    this.error,
  });

  final String id;
  final String label;
  final String description;
  final PassStatus status;
  final String output;
  final String? error;

  PipelinePass copyWith({
    PassStatus? status,
    String? output,
    String? error,
  }) {
    return PipelinePass(
      id: id,
      label: label,
      description: description,
      status: status ?? this.status,
      output: output ?? this.output,
      error: error,
    );
  }
}

/// Local lyric quality feedback (cliché hits + syllable notes).
class LyricFeedback {
  const LyricFeedback({
    required this.clicheHits,
    required this.syllableNotes,
    required this.sectionSummaries,
  });

  final List<ClicheHit> clicheHits;
  final List<String> syllableNotes;
  final List<SectionSyllableSummary> sectionSummaries;

  bool get hasIssues => clicheHits.isNotEmpty || syllableNotes.isNotEmpty;
}

class ClicheHit {
  const ClicheHit({
    required this.term,
    required this.familyLabel,
    required this.line,
    required this.lineIndex,
  });

  final String term;
  final String familyLabel;
  final String line;
  final int lineIndex;
}

class SectionSyllableSummary {
  const SectionSyllableSummary({
    required this.tag,
    required this.lineCounts,
    required this.min,
    required this.max,
    required this.avg,
  });

  final String tag;
  final List<int> lineCounts;
  final int min;
  final int max;
  final double avg;

  bool get isInconsistent {
    if (lineCounts.length < 2) return false;
    return (max - min) > 4;
  }
}
