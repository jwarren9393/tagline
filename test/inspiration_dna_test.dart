import 'package:flutter_test/flutter_test.dart';
import 'package:tagline/models/inspiration_dna.dart';
import 'package:tagline/models/song_idea.dart';

void main() {
  test('fingerprint changes when sources change', () {
    final a = InspirationDna.fingerprint(
      artist: 'Artist',
      song: 'Song',
      lyricsExcerpt: 'line one',
    );
    final b = InspirationDna.fingerprint(
      artist: 'Artist',
      song: 'Song',
      lyricsExcerpt: 'line two',
    );
    expect(a, isNot(equals(b)));
  });

  test('DNA prompt block forbids copying language', () {
    const dna = InspirationDna(
      sourceFingerprint: 'abc',
      summary: 'Sparse storytelling with dry humor.',
      sonicPalette: ['indie folk', 'close-mic'],
      lyricCraft: ['AABB couplets', 'second-person'],
      avoidCopying: ['signature hook X'],
      styleSeedHints: 'indie folk, intimate, 88 BPM',
      audioProfile: AudioProfile(
        source: 'deezer',
        trackTitle: 'Example',
        trackArtist: 'Artist',
        bpm: 88,
        durationSec: 240,
        gainDb: -8.2,
      ),
    );
    final block = dna.toPromptBlock();
    expect(block, contains('INSPIRATION DNA'));
    expect(block.toLowerCase(), contains('never copy'));
    expect(block, contains('DO NOT COPY'));
    expect(block, contains('AABB couplets'));
    expect(block, contains('MEASURED AUDIO PROFILE'));
    expect(block, contains('bpm: 88'));
  });

  test('AudioProfile round-trips JSON', () {
    const profile = AudioProfile(
      source: 'deezer',
      trackTitle: 'Fortunate',
      trackArtist: 'Maxwell',
      bpm: 126,
      durationSec: 298,
      gainDb: -10.4,
    );
    final again = AudioProfile.fromJson(profile.toJson());
    expect(again.bpm, 126);
    expect(again.hasBpm, isTrue);
    expect(again.bpmLabel, '126');
    expect(again.toPromptLines(), contains('bpm: 126'));
  });

  test('SongIdea marks DNA fresh only for matching fingerprint', () {
    const dna = InspirationDna(
      sourceFingerprint: 'deadbeef',
      summary: 'Test',
    );
    final idea = SongIdea(
      rawIdea: 'A real idea long enough',
      inspirationArtist: 'X',
      inspirationDna: dna,
    );
    expect(idea.hasInspirationSource, isTrue);
    expect(idea.inspirationDnaIsFresh, isFalse);

    final fp = InspirationDna.fingerprint(
      artist: 'X',
      song: '',
      lyricsExcerpt: '',
    );
    final fresh = idea.copyWith(
      inspirationDna: InspirationDna(
        sourceFingerprint: fp,
        summary: 'Fresh',
        sonicPalette: const ['soul'],
      ),
    );
    expect(fresh.inspirationDnaIsFresh, isTrue);
    expect(fresh.toPromptBlock(), contains('INSPIRATION DNA'));
  });
}
