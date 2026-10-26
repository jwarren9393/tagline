import 'package:flutter_test/flutter_test.dart';
import 'package:tagline/services/genius_client.dart';

void main() {
  test('extracts and scrubs lyrics containers from Genius-like HTML', () {
    const html = '''
<html><body>
<div data-lyrics-container="true">
[Verse 1]<br/>
Never seen a sun shine like this<br/>
<a href="/x">Never dug anyone like this</a>
</div>
<div data-lyrics-container="true">
[Chorus]<br/>
Fortunate to have you girl<br/>
You might also like<br/>
ALL RED<br/>
Playboi Carti<br/>
[Bridge]<br/>
Close the door no interlude
</div>
</body></html>
''';

    final raw = GeniusClient.extractLyricsFromHtml(html);
    final scrubbed = GeniusClient.scrubLyrics(raw);

    expect(scrubbed, contains('Never seen a sun shine like this'));
    expect(scrubbed, contains('Fortunate to have you girl'));
    expect(scrubbed, contains('Close the door no interlude'));
    expect(scrubbed.toLowerCase(), isNot(contains('you might also like')));
    expect(scrubbed, isNot(contains('Playboi Carti')));
    expect(scrubbed, isNot(contains('<br')));
  });

  test('unescapes basic HTML entities in lyrics', () {
    const html = '''
<div data-lyrics-container="true">I&#x27;m so glad you&#x27;re in my world</div>
''';
    final text = GeniusClient.scrubLyrics(GeniusClient.extractLyricsFromHtml(html));
    expect(text, contains("I'm so glad you're in my world"));
  });
}
