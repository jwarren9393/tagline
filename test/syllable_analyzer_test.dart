import 'package:flutter_test/flutter_test.dart';
import 'package:tagline/services/syllable_analyzer.dart';

void main() {
  test('counts simple words', () {
    expect(SyllableAnalyzer.countWord('coffee'), greaterThanOrEqualTo(2));
    expect(SyllableAnalyzer.countWord('oh'), 1);
  });

  test('analyzes sections', () {
    const lyrics = '''
[Verse 1]
Cold coffee on the counter
Keys still hanging by the door

[Chorus]
Stay a little longer, oh
''';
    final feedback = SyllableAnalyzer.analyze(lyrics);
    expect(feedback.sectionSummaries.length, 2);
    expect(feedback.sectionSummaries.first.tag, '[Verse 1]');
  });
}
