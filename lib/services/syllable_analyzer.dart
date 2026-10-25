import '../models/generation_result.dart';

/// Heuristic English syllable estimator + per-section consistency notes.
class SyllableAnalyzer {
  static final _tagRe = RegExp(r'^\s*\[.+\]\s*$');
  static final _parenRe = RegExp(r'\([^)]*\)');
  static final _nonWordRe = RegExp(r"[^a-zA-Z']+");

  static int countWord(String word) {
    var w = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (w.isEmpty) return 0;
    if (w.length <= 2) return 1;

    w = w.replaceAll(RegExp(r'e$'), '');
    w = w.replaceAll(RegExp(r'[^laeiouy]es$'), '');
    w = w.replaceAll(RegExp(r'[^laeiouy]ed$'), '');

    final matches = RegExp(r'[aeiouy]{1,2}').allMatches(w);
    var count = matches.length;
    if (count == 0) count = 1;
    return count;
  }

  static int countLine(String line) {
    final cleaned = line
        .replaceAll(_parenRe, ' ')
        .replaceAll(RegExp(r"[^\w\s']"), ' ');
    final words = cleaned
        .split(_nonWordRe)
        .where((w) => w.trim().isNotEmpty)
        .toList();
    return words.fold<int>(0, (sum, w) => sum + countWord(w));
  }

  static LyricFeedback analyze(String lyrics) {
    final lines = lyrics.split('\n');
    final sections = <SectionSyllableSummary>[];
    final notes = <String>[];

    String? currentTag;
    var currentCounts = <int>[];

    void flush() {
      if (currentTag == null || currentCounts.isEmpty) {
        currentCounts = [];
        return;
      }
      final min = currentCounts.reduce((a, b) => a < b ? a : b);
      final max = currentCounts.reduce((a, b) => a > b ? a : b);
      final avg =
          currentCounts.reduce((a, b) => a + b) / currentCounts.length;
      final tag = currentTag;
      final summary = SectionSyllableSummary(
        tag: tag,
        lineCounts: List.unmodifiable(currentCounts),
        min: min,
        max: max,
        avg: avg,
      );
      sections.add(summary);
      if (summary.isInconsistent) {
        notes.add(
          '${summary.tag}: syllable spread ${summary.min}–${summary.max} '
          '(avg ${summary.avg.toStringAsFixed(1)}). Aim tighter.',
        );
      }
      for (var i = 0; i < currentCounts.length; i++) {
        if (currentCounts[i] > 16) {
          notes.add(
            '${summary.tag} line ${i + 1}: ~${currentCounts[i]} syllables '
            '(may rush on Suno).',
          );
        }
      }
      currentCounts = [];
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) continue;
      if (_tagRe.hasMatch(line)) {
        flush();
        currentTag = line.trim();
        continue;
      }
      if (currentTag == null) continue;
      currentCounts.add(countLine(line));
    }
    flush();

    return LyricFeedback(
      clicheHits: const [],
      syllableNotes: notes,
      sectionSummaries: sections,
    );
  }
}
