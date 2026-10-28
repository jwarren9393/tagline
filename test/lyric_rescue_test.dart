import 'package:flutter_test/flutter_test.dart';
import 'package:tagline/models/lyric_rescue_input.dart';
import 'package:tagline/models/song_idea.dart';

void main() {
  test('rescue input requires substantial lyrics', () {
    expect(const LyricRescueInput(lyrics: 'short').isValid, isFalse);
    expect(
      LyricRescueInput(
        lyrics: List.filled(10, 'a line that sings').join('\n'),
      ).isValid,
      isTrue,
    );
  });

  test('SongIdea rescue mode validates via rescue lyrics', () {
    final idea = SongIdea(
      rawIdea: 'notes',
      mode: 'rescue',
      rescue: LyricRescueInput(
        lyrics: List.filled(12, 'verse line here').join('\n'),
        creatorNotes: 'soft apology',
      ),
    );
    expect(idea.isRescue, isTrue);
    expect(idea.isValid, isTrue);
    final json = idea.toJson();
    final again = SongIdea.fromJson(json);
    expect(again.isRescue, isTrue);
    expect(again.rescue!.creatorNotes, 'soft apology');
  });

  test('rescue prompt block includes creator intent', () {
    const input = LyricRescueInput(
      title: 'Still Countin',
      lyrics: '[Verse 1]\nSomething long enough to pass the gatekeepers here\n',
      stylePrompt: 'neo-soul, 88 BPM',
      creatorNotes: 'pride vs loneliness',
    );
    final block = input.toPromptBlock();
    expect(block, contains('CREATOR INTENT'));
    expect(block, contains('pride vs loneliness'));
    expect(block, contains('ORIGINAL STYLE'));
    expect(block, contains('neo-soul'));
    expect(block, contains('ACTIVE RESCUE CONSTRAINTS'));
    expect(block, contains('PRESERVE STRUCTURE STRICTLY'));
  });

  test('constraint flags round-trip and appear in prompt', () {
    const input = LyricRescueInput(
      lyrics: '[Verse 1]\nSomething long enough to pass the gatekeepers here\n',
      preserveStructureStrictly: false,
      tightenVerseLength: true,
      rewriteChorus: true,
    );
    final again = LyricRescueInput.fromJson(input.toJson());
    expect(again.preserveStructureStrictly, isFalse);
    expect(again.tightenVerseLength, isTrue);
    expect(again.rewriteChorus, isTrue);
    expect(again.activeConstraintLabels, contains('Tighten verses'));
    expect(again.activeConstraintLabels, contains('Rewrite chorus'));
    expect(again.activeConstraintLabels, contains('Flexible structure'));

    final block = again.toPromptBlock();
    expect(block, contains('TIGHTEN VERSE LENGTH'));
    expect(block, contains('REWRITE CHORUS'));
    expect(block, contains('FLEXIBLE STRUCTURE'));
  });

  test('legacy JSON defaults preserveStructureStrictly to true', () {
    final again = LyricRescueInput.fromJson({
      'lyrics': List.filled(10, 'a line that sings').join('\n'),
      'title': 'Old',
    });
    expect(again.preserveStructureStrictly, isTrue);
    expect(again.tightenVerseLength, isFalse);
    expect(again.rewriteChorus, isFalse);
  });
}
