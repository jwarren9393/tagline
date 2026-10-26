import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tagline/services/deezer_client.dart';

void main() {
  test('DeezerTrackHint brief includes bpm when present', () {
    const hint = DeezerTrackHint(
      id: '1',
      title: 'Fortunate',
      artistName: 'Maxwell',
      albumTitle: 'Embrya',
      bpm: 126,
      durationSec: 298,
      gainDb: -10.4,
    );
    expect(hint.hasBpm, isTrue);
    expect(hint.toBrief(), contains('bpm: 126'));
    expect(hint.toBrief(), contains('Maxwell - Fortunate'));
  });

  test('DeezerTrackHint treats zero bpm as missing', () {
    const hint = DeezerTrackHint(id: '2', title: 'X', bpm: 0);
    expect(hint.hasBpm, isFalse);
  });

  test('does not confuse Fortunate with Unfortunate', () async {
    final client = DeezerClient(
      httpClient: MockClient((req) async {
        if (req.url.path == '/search/track') {
          return http.Response(
            '''
{"data":[
  {"id":1,"title":"Fortunate","artist":{"name":"Maxwell"},"album":{"title":"Embrya"}},
  {"id":2,"title":"Unfortunate","artist":{"name":"Maxwell"},"album":{"title":"Now"}}
]}''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.url.path == '/track/2') {
          return http.Response(
            '''
{"id":2,"title":"Unfortunate","artist":{"name":"Maxwell"},
 "album":{"title":"Now"},"bpm":90,"duration":200,"gain":-9.0}''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error":"unexpected ${req.url}"}', 404);
      }),
    );
    final hint = await client.lookupTrack(
      artist: 'Maxwell',
      song: 'Unfortunate',
    );
    expect(hint.title, 'Unfortunate');
    expect(hint.bpm, 90);
  });

  test('returns empty when only other songs by same artist exist', () async {
    final client = DeezerClient(
      httpClient: MockClient((req) async {
        if (req.url.path == '/search/track') {
          return http.Response(
            '''
{"data":[
  {"id":10,"title":"Dazed","artist":{"name":"Daniel Merriweather"}},
  {"id":11,"title":"Everything I Need","artist":{"name":"Daniel Merriweather"}},
  {"id":12,"title":"Red (Made famous by Daniel Merriweather)","artist":{"name":"Karaoke"}}
]}''',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error":"should not fetch track"}', 500);
      }),
    );
    final hint = await client.lookupTrack(
      artist: 'Daniel Merriweather',
      song: 'Red',
    );
    expect(hint.isEmpty, isTrue);
  });

  test('requires a song title', () async {
    final client = DeezerClient(
      httpClient: MockClient((req) async {
        fail('should not call API without song title');
        return http.Response('{}', 200);
      }),
    );
    final hint = await client.lookupTrack(
      artist: 'Daniel Merriweather',
      song: '',
    );
    expect(hint.isEmpty, isTrue);
  });
}
