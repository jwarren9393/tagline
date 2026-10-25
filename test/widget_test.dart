import 'package:flutter_test/flutter_test.dart';
import 'package:tagline/data/genre_templates.dart';
import 'package:tagline/models/song_idea.dart';

void main() {
  test('SongIdea builds prompt block with genre', () {
    const idea = SongIdea(
      rawIdea: 'Cold coffee and a truck that will not start at 5am.',
      genreId: 'indie_folk',
      moods: ['Bittersweet'],
    );
    expect(idea.isValid, isTrue);
    final block = idea.toPromptBlock();
    expect(block, contains('Indie Folk'));
    expect(block, contains('Bittersweet'));
    expect(genreById('indie_folk'), isNotNull);
  });
}
