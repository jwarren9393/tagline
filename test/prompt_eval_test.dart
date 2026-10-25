import 'package:flutter_test/flutter_test.dart';
import 'package:tagline/data/eval_fixtures.dart';
import 'package:tagline/services/prompt_eval.dart';

void main() {
  const eval = PromptEval();

  test('good fixture scores strongly', () {
    final summary = eval.evaluate(
      lyrics: kGoodLyricsFixture,
      style: kGoodStyleFixture,
      exclude: kGoodExcludeFixture,
    );
    expect(summary.ratio, greaterThanOrEqualTo(0.85));
    expect(
      summary.checks.where((c) => !c.passed).map((c) => c.id),
      isEmpty,
    );
  });

  test('bad fixture scores poorly and fails key checks', () {
    final summary = eval.evaluate(
      lyrics: kBadLyricsFixture,
      style: kBadStyleFixture,
    );
    expect(summary.ratio, lessThan(0.65));
    final failed = summary.checks.where((c) => !c.passed).map((c) => c.id);
    expect(failed, contains('cliche_density'));
    expect(failed, contains('style_no_story'));
    expect(failed, contains('style_no_negatives'));
  });

  test('chorus verbatim check catches drift', () {
    const lyrics = '''
[Chorus]
Stay a little longer, oh

[Verse 1]
Something concrete on the counter

[Chorus]
Stay a little longer now
''';
    final summary = eval.evaluate(
      lyrics: lyrics,
      style: kGoodStyleFixture,
    );
    final chorus = summary.checks.firstWhere((c) => c.id == 'chorus_repeat');
    expect(chorus.passed, isFalse);
  });
}
