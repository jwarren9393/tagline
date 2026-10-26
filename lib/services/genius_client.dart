import 'dart:convert';

import 'package:http/http.dart' as http;

import 'track_match.dart';

/// Genius search + ephemeral lyrics fetch for Inspiration DNA analysis.
///
/// Lyrics are used only in-memory to distill abstract craft patterns.
/// They must never be written into Style/Lyrics outputs or treated as a cover.
///
/// When a song title is given, only a real title match is returned — never the
/// first unrelated search hit.
class GeniusClient {
  GeniusClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _userAgent =
      'Tagline/1.0 (https://github.com/jwarren9393/tagline; inspiration-dna)';

  /// Search Genius and optionally load lyrics for the best song hit.
  Future<GeniusSongHint> lookupSong({
    required String artist,
    required String song,
    bool fetchLyrics = true,
  }) async {
    final a = artist.trim();
    final s = song.trim();
    final query = [a, s].where((e) => e.isNotEmpty).join(' ').trim();
    if (query.isEmpty) return const GeniusSongHint();

    final searchUri = Uri.https('genius.com', '/api/search', {'q': query});
    final searchRes = await _http.get(
      searchUri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      },
    );
    if (searchRes.statusCode != 200) return const GeniusSongHint();

    final decoded = jsonDecode(searchRes.body);
    if (decoded is! Map) return const GeniusSongHint();
    final response = decoded['response'];
    if (response is! Map) return const GeniusSongHint();
    final hits = response['hits'];
    if (hits is! List || hits.isEmpty) return const GeniusSongHint();

    Map<String, dynamic>? best;
    var bestScore = 0;
    for (final hit in hits) {
      if (hit is! Map) continue;
      if ('${hit['type']}' != 'song') continue;
      final result = hit['result'];
      if (result is! Map) continue;
      final map = Map<String, dynamic>.from(result);
      final score = _matchScore(map, artist: a, song: s);
      if (score > bestScore) {
        bestScore = score;
        best = map;
      }
    }
    if (best == null || bestScore <= 0) return const GeniusSongHint();

    final title = '${best['title'] ?? ''}'.trim();
    final fullTitle = '${best['full_title'] ?? title}'.trim();
    final url = '${best['url'] ?? ''}'.trim();
    final primary = best['primary_artist'];
    var artistName = a;
    if (primary is Map) {
      final n = '${primary['name'] ?? ''}'.trim();
      if (n.isNotEmpty) artistName = n;
    }

    var lyrics = '';
    if (fetchLyrics && url.isNotEmpty) {
      try {
        lyrics = await fetchLyricsFromUrl(url);
      } catch (_) {
        lyrics = '';
      }
    }

    return GeniusSongHint(
      title: title,
      fullTitle: fullTitle,
      artistName: artistName,
      url: url,
      lyrics: lyrics,
    );
  }

  /// >0 only for a usable match. Song title required → title must match.
  int _matchScore(
    Map<String, dynamic> result, {
    required String artist,
    required String song,
  }) {
    final title = '${result['title'] ?? ''}'.trim();
    final fullTitle = '${result['full_title'] ?? title}'.trim();
    final primary = result['primary_artist'];
    final artistName = primary is Map
        ? '${primary['name'] ?? ''}'.trim()
        : '';
    final blob = '$artistName $title $fullTitle';
    if (TrackMatch.isJunkCover(blob)) return 0;

    if (song.isNotEmpty) {
      final titleOk = TrackMatch.titleMatches(title, song) ||
          TrackMatch.titleMatches(fullTitle, song);
      if (!titleOk) return 0;
    }
    if (artist.isNotEmpty &&
        artistName.isNotEmpty &&
        !TrackMatch.artistMatches(artistName, artist)) {
      return 0;
    }

    var score = song.isEmpty ? 3 : 10;
    if (song.isNotEmpty && TrackMatch.norm(title) == TrackMatch.norm(song)) {
      score += 5;
    }
    if (artist.isNotEmpty &&
        TrackMatch.norm(artistName) == TrackMatch.norm(artist)) {
      score += 5;
    }
    return score;
  }

  Future<String> fetchLyricsFromUrl(String pageUrl) async {
    final res = await _http.get(
      Uri.parse(pageUrl),
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'text/html',
      },
    );
    if (res.statusCode != 200) return '';
    return scrubLyrics(extractLyricsFromHtml(res.body));
  }

  /// Depth-walk Genius `data-lyrics-container` blocks out of a song page.
  static String extractLyricsFromHtml(String html) {
    const needle = 'data-lyrics-container="true"';
    final chunks = <String>[];
    var i = 0;
    while (true) {
      final j = html.indexOf(needle, i);
      if (j < 0) break;
      final gt = html.indexOf('>', j);
      if (gt < 0) break;
      var pos = gt + 1;
      var depth = 1;
      var k = pos;
      while (k < html.length && depth > 0) {
        final nextOpen = html.indexOf('<div', k);
        final nextClose = html.indexOf('</div>', k);
        if (nextClose < 0) break;
        if (nextOpen >= 0 && nextOpen < nextClose) {
          depth++;
          k = nextOpen + 4;
        } else {
          depth--;
          if (depth == 0) {
            chunks.add(html.substring(pos, nextClose));
            i = nextClose + 6;
            break;
          }
          k = nextClose + 6;
        }
      }
      if (depth != 0) break;
    }

    final text = chunks.map(_stripHtml).where((e) => e.trim().isNotEmpty);
    return text.join('\n\n');
  }

  static String _stripHtml(String fragment) {
    var s = fragment.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</?a\b[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    return _unescapeHtml(s);
  }

  static String _unescapeHtml(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  /// Remove Genius chrome / related-song junk from extracted lyrics.
  static String scrubLyrics(String raw) {
    var s = raw;
    s = s.replaceAll(
      RegExp(r'^\d+\s+Contributors.*$', multiLine: true),
      '',
    );
    // Drop Genius "You might also like" promo blocks until the next section tag.
    s = s.replaceAllMapped(
      RegExp(r'You might also like[\s\S]*', caseSensitive: false),
      (m) {
        final rest = m.group(0) ?? '';
        final nextTag = RegExp(r'\n\s*\[').firstMatch(rest);
        if (nextTag == null) return '';
        return rest.substring(nextTag.start);
      },
    );
    s = s.replaceAll(RegExp(r'^Embed\s*$', multiLine: true), '');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }
}

class GeniusSongHint {
  const GeniusSongHint({
    this.title = '',
    this.fullTitle = '',
    this.artistName = '',
    this.url = '',
    this.lyrics = '',
  });

  final String title;
  final String fullTitle;
  final String artistName;
  final String url;
  final String lyrics;

  bool get isEmpty => title.isEmpty && url.isEmpty && lyrics.isEmpty;

  bool get hasLyrics => lyrics.trim().isNotEmpty;

  String toBrief() {
    final parts = <String>[];
    if (fullTitle.isNotEmpty) {
      parts.add(fullTitle);
    } else if (title.isNotEmpty) {
      parts.add(title);
    }
    if (artistName.isNotEmpty) parts.add('artist: $artistName');
    if (url.isNotEmpty) parts.add(url);
    if (hasLyrics) parts.add('lyrics_chars: ${lyrics.trim().length}');
    return parts.join(' · ');
  }
}
