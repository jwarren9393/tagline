import '../models/inspiration_dna.dart';
import '../prompts/system_prompts.dart';
import 'deezer_client.dart';
import 'genius_client.dart';
import 'musicbrainz_client.dart';
import 'nanogpt_client.dart' show NanoGptClient, TokenCallback, extractJsonObject;

/// Builds abstract inspiration DNA from artist / song / user-pasted lyrics.
///
/// Enrichment:
/// - MusicBrainz → public artist tags
/// - Genius → song match + ephemeral lyrics for pattern analysis only
/// - Deezer → measured BPM / duration / replay gain when catalogued
///
/// Fetched Genius lyrics are NEVER persisted into SongIdea / session exports
/// and must never appear in Style or Lyrics outputs.
class InspirationDnaService {
  InspirationDnaService(
    this._client, {
    MusicBrainzClient? musicBrainz,
    GeniusClient? genius,
    DeezerClient? deezer,
  })  : _mb = musicBrainz ?? MusicBrainzClient(),
        _genius = genius ?? GeniusClient(),
        _deezer = deezer ?? DeezerClient();

  final NanoGptClient _client;
  final MusicBrainzClient _mb;
  final GeniusClient _genius;
  final DeezerClient _deezer;

  Future<InspirationDna> extract({
    required String artist,
    required String song,
    required String lyricsExcerpt,
    TokenCallback? onToken,
  }) async {
    final a = artist.trim();
    final s = song.trim();
    final pasted = lyricsExcerpt.trim();
    if (a.isEmpty && s.isEmpty && pasted.isEmpty) {
      throw const InspirationDnaException(
        'Add an artist, song title, and/or a short lyrics excerpt first.',
      );
    }

    // Fingerprint user-facing sources only (not ephemeral Genius fetch).
    final fp = InspirationDna.fingerprint(
      artist: a,
      song: s,
      lyricsExcerpt: pasted,
    );

    MusicBrainzArtistHint mbHint = const MusicBrainzArtistHint();
    if (a.isNotEmpty) {
      try {
        mbHint = await _mb.lookupArtist(a);
      } catch (_) {}
    }

    GeniusSongHint geniusHint = const GeniusSongHint();
    if (a.isNotEmpty || s.isNotEmpty) {
      try {
        geniusHint = await _genius.lookupSong(
          artist: a,
          song: s,
          // Always allow Genius lyrics for analysis when artist/song present.
          // Pasted excerpt still wins as the primary lyric body below.
          fetchLyrics: true,
        );
      } catch (_) {}
    }

    DeezerTrackHint deezerHint = const DeezerTrackHint();
    AudioProfile? audioProfile;
    if (a.isNotEmpty || s.isNotEmpty) {
      try {
        deezerHint = await _deezer.lookupTrack(artist: a, song: s);
        if (!deezerHint.isEmpty) {
          audioProfile = AudioProfile(
            source: 'deezer',
            trackTitle: deezerHint.title,
            trackArtist: deezerHint.artistName,
            albumTitle: deezerHint.albumTitle,
            bpm: deezerHint.hasBpm ? deezerHint.bpm : null,
            durationSec: deezerHint.durationSec,
            gainDb: deezerHint.gainDb,
            notes: deezerHint.hasBpm
                ? const [
                    'BPM is catalog-measured; for ballads/R&B consider '
                        'half-time feel if the number reads double-time.',
                  ]
                : const [
                    'Deezer match found but BPM missing — estimate tempo '
                        'from genre/feel and label it estimated.',
                  ],
          );
        }
      } catch (_) {}
    }

    final analysisLyrics = pasted.isNotEmpty
        ? pasted
        : (geniusHint.hasLyrics ? geniusHint.lyrics.trim() : '');

    final sources = <String>[];
    if (!mbHint.isEmpty) sources.add('musicbrainz');
    if (!geniusHint.isEmpty) sources.add('genius');
    if (!deezerHint.isEmpty) sources.add('deezer');
    if (pasted.isNotEmpty) sources.add('user_paste');

    final user = StringBuffer()
      ..writeln('Build Inspiration DNA for an ORIGINAL new song.')
      ..writeln('Reference artist: ${a.isEmpty ? '(none)' : a}')
      ..writeln('Reference song title: ${s.isEmpty ? '(none)' : s}');
    if (!mbHint.isEmpty) {
      user.writeln('MusicBrainz public metadata: ${mbHint.toBrief()}');
    }
    if (!geniusHint.isEmpty) {
      user.writeln(
        'Genius song match (metadata only in this line): ${geniusHint.toBrief()}',
      );
    }
    if (audioProfile != null && !audioProfile.isEmpty) {
      user
        ..writeln('MEASURED AUDIO PROFILE (Deezer catalog — prefer these '
            'numbers over guesses for Style):')
        ..writeln(audioProfile.toPromptLines());
    }
    if (analysisLyrics.isNotEmpty) {
      final body = analysisLyrics.length > 4000
          ? analysisLyrics.substring(0, 4000)
          : analysisLyrics;
      user
        ..writeln()
        ..writeln(
          pasted.isNotEmpty
              ? 'USER-PASTED LYRICS EXCERPT (private analysis only — '
                  'extract patterns; NEVER quote or reuse lines):'
              : 'GENIUS-FETCHED LYRICS (ephemeral private analysis only — '
                  'extract patterns; NEVER quote, reuse, or reproduce lines; '
                  'do not mention Genius in the song text):',
        )
        ..writeln(body);
    }
    user
      ..writeln()
      ..writeln(
        'Return JSON only. Prefer transferable craft + sonic traits. '
        'Use ONLY the enrichment blocks above — if Deezer/Genius/MusicBrainz '
        'is missing, do not invent a match, BPM, or album for that source. '
        'Partial sources are fine. Fold measured BPM/duration/loudness into '
        'style_seed_hints when present. If unsure, stay general in summary.',
      );

    final raw = await _client.chat(
      system: SystemPrompts.inspirationDnaSystem(),
      user: user.toString(),
      temperature: 0.55,
      onToken: onToken,
    );

    try {
      final map = extractJsonObject(raw);
      final dna = InspirationDna.fromJson({
        'sourceFingerprint': fp,
        'summary': map['summary'] ?? '',
        'sonicPalette': map['sonic_palette'] ?? map['sonicPalette'] ?? const [],
        'lyricCraft': map['lyric_craft'] ?? map['lyricCraft'] ?? const [],
        'thematicTerritory':
            map['thematic_territory'] ?? map['thematicTerritory'] ?? const [],
        'avoidCopying':
            map['avoid_copying'] ?? map['avoidCopying'] ?? const [],
        'vocalCharacter':
            map['vocal_character'] ?? map['vocalCharacter'] ?? '',
        'productionHints':
            map['production_hints'] ?? map['productionHints'] ?? '',
        'styleSeedHints':
            map['style_seed_hints'] ?? map['styleSeedHints'] ?? '',
        'musicBrainzTags': mbHint.tags,
        'sources': sources,
        'geniusUrl': geniusHint.url,
        'geniusTitle': geniusHint.fullTitle.isNotEmpty
            ? geniusHint.fullTitle
            : geniusHint.title,
        if (audioProfile != null) 'audioProfile': audioProfile.toJson(),
        'extractedAt': DateTime.now().toUtc().toIso8601String(),
      });
      if (dna.isEmpty) {
        throw const InspirationDnaException(
          'DNA extract returned empty — try a clearer artist/song or paste a short excerpt.',
        );
      }
      return dna;
    } catch (e) {
      if (e is InspirationDnaException) rethrow;
      throw InspirationDnaException('Could not parse inspiration DNA: $e');
    }
  }
}

class InspirationDnaException implements Exception {
  const InspirationDnaException(this.message);
  final String message;

  @override
  String toString() => message;
}
