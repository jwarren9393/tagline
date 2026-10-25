import '../data/cliche_families.dart';
import '../models/generation_result.dart';

/// Local scan for overused cliché families in lyrics.
class ClicheDetector {
  static List<ClicheHit> scan(String lyrics) {
    final lines = lyrics.split('\n');
    final hits = <ClicheHit>[];
    final tagRe = RegExp(r'^\s*\[.+\]\s*$');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (tagRe.hasMatch(line) || line.trim().isEmpty) continue;
      final lower = line.toLowerCase();

      for (final family in kClicheFamilies) {
        for (final term in family.terms) {
          if (lower.contains(term.toLowerCase())) {
            hits.add(ClicheHit(
              term: term,
              familyLabel: family.label,
              line: line.trim(),
              lineIndex: i + 1,
            ));
          }
        }
      }
    }
    return hits;
  }

  static LyricFeedback combineWithSyllables({
    required String lyrics,
    required LyricFeedback syllableFeedback,
  }) {
    return LyricFeedback(
      clicheHits: scan(lyrics),
      syllableNotes: syllableFeedback.syllableNotes,
      sectionSummaries: syllableFeedback.sectionSummaries,
    );
  }
}
