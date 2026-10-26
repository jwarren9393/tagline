import 'dart:convert';

import 'package:http/http.dart' as http;

import 'track_match.dart';

/// Deezer public API enrichment: BPM, duration, loudness gain, album context.
/// No API key required. Coverage varies — bpm may be 0/missing for some tracks.
///
/// Only returns a hit when the catalog title actually matches the requested
/// song (and artist, when given). Artist-only neighbors are never used.
class DeezerClient {
  DeezerClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _userAgent =
      'Tagline/1.0 (https://github.com/jwarren9393/tagline; inspiration-dna)';

  Future<DeezerTrackHint> lookupTrack({
    required String artist,
    required String song,
  }) async {
    final a = artist.trim();
    final s = song.trim();
    if (a.isEmpty && s.isEmpty) return const DeezerTrackHint();

    // Song title is required for audio attachment — without it we would only
    // guess among an artist's catalog.
    if (s.isEmpty) return const DeezerTrackHint();

    final query = [a, s].where((e) => e.isNotEmpty).join(' ');
    final uri = Uri.https('api.deezer.com', '/search/track', {
      'q': query,
      'limit': '12',
    });
    final res = await _http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      },
    );
    if (res.statusCode != 200) return const DeezerTrackHint();

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) return const DeezerTrackHint();
    final data = decoded['data'];
    if (data is! List || data.isEmpty) return const DeezerTrackHint();

    final ranked = <({Map<String, dynamic> track, int score})>[];
    for (final item in data) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final score = _matchScore(map, artist: a, song: s);
      if (score <= 0) continue;
      ranked.add((track: map, score: score));
    }
    if (ranked.isEmpty) return const DeezerTrackHint();
    ranked.sort((x, y) => y.score.compareTo(x.score));

    // Prefer a title-matched hit that also has BPM; never leave the match set.
    Map<String, dynamic>? chosen;
    for (final cand in ranked.take(5)) {
      final id = cand.track['id'];
      if (id == null) continue;
      final full = await _fetchTrack('$id');
      final map = full ?? cand.track;
      // Re-verify title after detail fetch (safety).
      final title = '${map['title'] ?? ''}'.trim();
      if (!TrackMatch.titleMatches(title, s)) continue;
      chosen = map;
      final bpm = _asDouble(map['bpm']);
      if (bpm != null && bpm > 0) break;
    }
    if (chosen == null) return const DeezerTrackHint();

    return DeezerTrackHint(
      id: '${chosen['id'] ?? ''}',
      title: '${chosen['title'] ?? ''}'.trim(),
      artistName: '${(chosen['artist'] is Map) ? chosen['artist']['name'] : ''}'
          .trim(),
      albumTitle:
          '${(chosen['album'] is Map) ? chosen['album']['title'] : ''}'.trim(),
      bpm: _asDouble(chosen['bpm']),
      durationSec: _asInt(chosen['duration']),
      gainDb: _asDouble(chosen['gain']),
      rank: _asInt(chosen['rank']),
      link: '${chosen['link'] ?? ''}'.trim(),
    );
  }

  Future<Map<String, dynamic>?> _fetchTrack(String id) async {
    final uri = Uri.https('api.deezer.com', '/track/$id');
    final res = await _http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      },
    );
    if (res.statusCode != 200) return null;
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  /// Score > 0 only when the title matches the requested song.
  int _matchScore(
    Map<String, dynamic> track, {
    required String artist,
    required String song,
  }) {
    final title = '${track['title'] ?? ''}'.trim();
    final artistName =
        '${(track['artist'] is Map) ? track['artist']['name'] : ''}'.trim();
    final blob = '$artistName $title';
    if (TrackMatch.isJunkCover(blob)) return 0;
    if (!TrackMatch.titleMatches(title, song)) return 0;
    if (artist.isNotEmpty && !TrackMatch.artistMatches(artistName, artist)) {
      return 0;
    }

    var score = 10; // title matched
    final a = TrackMatch.norm(artist);
    final an = TrackMatch.norm(artistName);
    final t = TrackMatch.norm(title);
    final s = TrackMatch.norm(song);
    if (a.isNotEmpty && an == a) score += 5;
    if (t == s) score += 5;
    return score;
  }

  double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v'.trim());
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse('$v'.trim());
  }
}

class DeezerTrackHint {
  const DeezerTrackHint({
    this.id = '',
    this.title = '',
    this.artistName = '',
    this.albumTitle = '',
    this.bpm,
    this.durationSec,
    this.gainDb,
    this.rank,
    this.link = '',
  });

  final String id;
  final String title;
  final String artistName;
  final String albumTitle;
  final double? bpm;
  final int? durationSec;
  final double? gainDb;
  final int? rank;
  final String link;

  bool get isEmpty => title.isEmpty && id.isEmpty;

  bool get hasBpm => bpm != null && bpm! > 0;

  String toBrief() {
    final parts = <String>[];
    if (artistName.isNotEmpty && title.isNotEmpty) {
      parts.add('$artistName - $title');
    } else if (title.isNotEmpty) {
      parts.add(title);
    }
    if (hasBpm) {
      parts.add('bpm: ${bpm!.toStringAsFixed(bpm! % 1 == 0 ? 0 : 1)}');
    }
    if (durationSec != null && durationSec! > 0) {
      parts.add('duration_sec: $durationSec');
    }
    if (gainDb != null) parts.add('gain_db: ${gainDb!.toStringAsFixed(2)}');
    if (albumTitle.isNotEmpty) parts.add('album: $albumTitle');
    return parts.join(' · ');
  }
}
