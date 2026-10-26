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

  test('chorus verbatim check catches sung-line drift', () {
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

  test('chorus ad-lib variance does not fail verbatim check', () {
    const lyrics = '''
[Chorus]
I'm still countin' what I cost ya
Every busted hinge and frame
(Oh, still countin')

[Verse 1]
I'm up before the furnace kicks
Just me and how the floorboard ticks

[Chorus]
I'm still countin' what I cost ya
Every busted hinge and frame
(Lord, I'm countin')
''';
    final summary = eval.evaluate(
      lyrics: lyrics,
      style: kGoodStyleFixture,
    );
    final chorus = summary.checks.firstWhere((c) => c.id == 'chorus_repeat');
    expect(chorus.passed, isTrue);
  });

  test('style may mention chorus musically without failing', () {
    final summary = eval.evaluate(
      lyrics: kGoodLyricsFixture,
      style:
          'Southern soul, male deep tenor, sorrowful gospel choir swelling on chorus, 64 BPM',
      exclude: kGoodExcludeFixture,
    );
    final story = summary.checks.firstWhere((c) => c.id == 'style_no_story');
    expect(story.passed, isTrue);
  });

  test('verse rhyme check passes good fixture and fails free verse', () {
    final good = eval.evaluate(
      lyrics: kGoodLyricsFixture,
      style: kGoodStyleFixture,
      exclude: kGoodExcludeFixture,
    );
    expect(
      good.checks.firstWhere((c) => c.id == 'verse_rhyme').passed,
      isTrue,
    );

    const freeVerse = '''
[Verse 1]
Clock says 12:03
Same crack in the ceiling memorized
This chip in my hand's almost smooth
Been rubbing it a year
You'd think I'd feel something by now
I don't

[Chorus]
Still here
Still here
''';
    final bad = eval.evaluate(
      lyrics: freeVerse,
      style: kGoodStyleFixture,
    );
    expect(
      bad.checks.firstWhere((c) => c.id == 'verse_rhyme').passed,
      isFalse,
    );
  });
}
