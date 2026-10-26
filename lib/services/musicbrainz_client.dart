import 'dart:convert';

import 'package:http/http.dart' as http;

/// Lightweight MusicBrainz lookup for public artist tags / disambiguation.
/// Does NOT fetch lyrics. Requires a descriptive User-Agent per MB policy.
class MusicBrainzClient {
  MusicBrainzClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _base = 'https://musicbrainz.org/ws/2';
  static const _userAgent = 'Tagline/1.0 (https://github.com/jwarren9393/tagline)';

  /// Returns genre-ish tags and a display name for [artistQuery], or empty.
  Future<MusicBrainzArtistHint> lookupArtist(String artistQuery) async {
    final q = artistQuery.trim();
    if (q.isEmpty) return const MusicBrainzArtistHint();

    final uri = Uri.parse('$_base/artist').replace(queryParameters: {
      'query': 'artist:${_escapeLucene(q)}',
      'fmt': 'json',
      'limit': '1',
    });

    final res = await _http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      },
    );
    if (res.statusCode != 200) {
      return const MusicBrainzArtistHint();
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) return const MusicBrainzArtistHint();
    final artists = decoded['artists'];
    if (artists is! List || artists.isEmpty) {
      return const MusicBrainzArtistHint();
    }
    final first = artists.first;
    if (first is! Map) return const MusicBrainzArtistHint();
    final map = Map<String, dynamic>.from(first);
    final name = '${map['name'] ?? q}'.trim();
    // Reject clearly wrong artists (first Lucene hit can be a near-miss).
    final nq = q.toLowerCase();
    final nn = name.toLowerCase();
    if (nn != nq && !nn.contains(nq) && !nq.contains(nn)) {
      return const MusicBrainzArtistHint();
    }
    final tags = <String>[];
    final rawTags = map['tags'];
    if (rawTags is List) {
      final scored = <({String name, int count})>[];
      for (final t in rawTags) {
        if (t is! Map) continue;
        final n = '${t['name'] ?? ''}'.trim();
        final c = t['count'] is int
            ? t['count'] as int
            : int.tryParse('${t['count']}') ?? 0;
        if (n.isNotEmpty) scored.add((name: n, count: c));
      }
      scored.sort((a, b) => b.count.compareTo(a.count));
      tags.addAll(scored.take(8).map((e) => e.name));
    }
    final type = '${map['type'] ?? ''}'.trim();
    final country = '${map['country'] ?? ''}'.trim();
    return MusicBrainzArtistHint(
      name: name,
      type: type,
      country: country,
      tags: tags,
    );
  }

  String _escapeLucene(String input) {
    return input.replaceAll(RegExp(r'([+\-&|!(){}\[\]^"~*?:\\/])'), r'\$1');
  }
}

class MusicBrainzArtistHint {
  const MusicBrainzArtistHint({
    this.name = '',
    this.type = '',
    this.country = '',
    this.tags = const [],
  });

  final String name;
  final String type;
  final String country;
  final List<String> tags;

  bool get isEmpty => name.isEmpty && tags.isEmpty;

  String toBrief() {
    final parts = <String>[];
    if (name.isNotEmpty) parts.add(name);
    if (type.isNotEmpty) parts.add(type);
    if (country.isNotEmpty) parts.add(country);
    if (tags.isNotEmpty) parts.add('tags: ${tags.join(', ')}');
    return parts.join(' · ');
  }
}
