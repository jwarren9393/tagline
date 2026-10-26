import 'package:flutter_test/flutter_test.dart';
import 'package:tagline/services/track_match.dart';

void main() {
  test('titleMatches exact and featured suffixes', () {
    expect(TrackMatch.titleMatches('Red', 'red'), isTrue);
    expect(TrackMatch.titleMatches('Red (feat. Adele)', 'Red'), isTrue);
    expect(TrackMatch.titleMatches('Red - Live', 'Red'), isTrue);
  });

  test('titleMatches rejects artist-neighbor and substring traps', () {
    expect(
      TrackMatch.titleMatches('Everything I Need', 'Red'),
      isFalse,
    );
    expect(TrackMatch.titleMatches('Fortunate', 'Unfortunate'), isFalse);
    expect(TrackMatch.titleMatches('Unfortunate', 'Fortunate'), isFalse);
  });

  test('junk cover detection', () {
    expect(
      TrackMatch.isJunkCover(
        'PMC All-Stars - Red (Made famous by Daniel Merriweather)',
      ),
      isTrue,
    );
    expect(
      TrackMatch.isJunkCover('Daniel Merriweather - Red'),
      isFalse,
    );
  });
}
