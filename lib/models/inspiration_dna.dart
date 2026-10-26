import 'dart:convert';

/// Abstract stylistic "DNA" distilled from a reference artist/song/lyrics paste.
/// Never contains copyrighted lyric text — only transferable craft/sonic traits.
class InspirationDna {
  const InspirationDna({
    required this.sourceFingerprint,
    required this.summary,
    this.sonicPalette = const [],
    this.lyricCraft = const [],
    this.thematicTerritory = const [],
    this.avoidCopying = const [],
    this.vocalCharacter = '',
    this.productionHints = '',
    this.styleSeedHints = '',
    this.musicBrainzTags = const [],
    this.sources = const [],
    this.geniusUrl = '',
    this.geniusTitle = '',
    this.audioProfile,
    this.extractedAt,
  });

  /// Hash of artist|song|user-pasted excerpt used to build this DNA.
  final String sourceFingerprint;
  final String summary;
  final List<String> sonicPalette;
  final List<String> lyricCraft;
  final List<String> thematicTerritory;

  /// Distinctive hooks/phrases/structures to steer clear of.
  final List<String> avoidCopying;
  final String vocalCharacter;
  final String productionHints;
  final String styleSeedHints;
  final List<String> musicBrainzTags;

  /// e.g. musicbrainz, genius, deezer, user_paste
  final List<String> sources;
  final String geniusUrl;
  final String geniusTitle;
  final AudioProfile? audioProfile;
  final DateTime? extractedAt;

  bool get isEmpty =>
      summary.trim().isEmpty &&
      sonicPalette.isEmpty &&
      lyricCraft.isEmpty &&
      styleSeedHints.trim().isEmpty &&
      audioProfile == null;

  String toPromptBlock() {
    if (isEmpty) return '';
    final buf = StringBuffer();
    buf.writeln('INSPIRATION DNA (abstract formula ONLY — never copy lyrics, '
        'melodies, titles, or distinctive phrases from the reference):');
    if (summary.trim().isNotEmpty) {
      buf.writeln('SUMMARY: ${summary.trim()}');
    }
    if (sonicPalette.isNotEmpty) {
      buf.writeln('SONIC PALETTE: ${sonicPalette.join('; ')}');
    }
    if (lyricCraft.isNotEmpty) {
      buf.writeln('LYRIC CRAFT PATTERNS: ${lyricCraft.join('; ')}');
    }
    if (thematicTerritory.isNotEmpty) {
      buf.writeln('THEMATIC TERRITORY (explore nearby, do not retell): '
          '${thematicTerritory.join('; ')}');
    }
    if (vocalCharacter.trim().isNotEmpty) {
      buf.writeln('VOCAL CHARACTER: ${vocalCharacter.trim()}');
    }
    if (productionHints.trim().isNotEmpty) {
      buf.writeln('PRODUCTION HINTS: ${productionHints.trim()}');
    }
    if (styleSeedHints.trim().isNotEmpty) {
      buf.writeln('STYLE SEED HINTS: ${styleSeedHints.trim()}');
    }
    if (musicBrainzTags.isNotEmpty) {
      buf.writeln('PUBLIC TAGS (MusicBrainz): ${musicBrainzTags.join(', ')}');
    }
    if (sources.isNotEmpty) {
      buf.writeln('DNA SOURCES: ${sources.join(', ')}');
    }
    if (geniusTitle.trim().isNotEmpty) {
      buf.writeln('GENIUS MATCH: ${geniusTitle.trim()}');
    }
    if (audioProfile != null && !audioProfile!.isEmpty) {
      buf.writeln('MEASURED AUDIO PROFILE (${audioProfile!.source}):');
      buf.writeln(audioProfile!.toPromptLines());
      buf.writeln(
        'Use measured BPM/duration/loudness as the Style baseline when present. '
        'If BPM looks double-time for a ballad/R&B feel, prefer a musical '
        'half-time reading and note it in style_seed_hints.',
      );
    }
    if (avoidCopying.isNotEmpty) {
      buf.writeln('DO NOT COPY / ECHO: ${avoidCopying.join('; ')}');
    }
    buf.writeln(
      'Write an ORIGINAL song inspired by this DNA. New scenes, new lines, '
      'new hook. If a line would sound like the reference, rewrite it.',
    );
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'sourceFingerprint': sourceFingerprint,
        'summary': summary,
        'sonicPalette': sonicPalette,
        'lyricCraft': lyricCraft,
        'thematicTerritory': thematicTerritory,
        'avoidCopying': avoidCopying,
        'vocalCharacter': vocalCharacter,
        'productionHints': productionHints,
        'styleSeedHints': styleSeedHints,
        'musicBrainzTags': musicBrainzTags,
        'sources': sources,
        'geniusUrl': geniusUrl,
        'geniusTitle': geniusTitle,
        if (audioProfile != null) 'audioProfile': audioProfile!.toJson(),
        'extractedAt': extractedAt?.toUtc().toIso8601String(),
      };

  factory InspirationDna.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic v) => (v is List)
        ? v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : const [];

    AudioProfile? audio;
    final rawAudio = json['audioProfile'];
    if (rawAudio is Map) {
      audio = AudioProfile.fromJson(Map<String, dynamic>.from(rawAudio));
    }

    return InspirationDna(
      sourceFingerprint: '${json['sourceFingerprint'] ?? ''}',
      summary: '${json['summary'] ?? ''}',
      sonicPalette: strList(json['sonicPalette']),
      lyricCraft: strList(json['lyricCraft']),
      thematicTerritory: strList(json['thematicTerritory']),
      avoidCopying: strList(json['avoidCopying']),
      vocalCharacter: '${json['vocalCharacter'] ?? ''}',
      productionHints: '${json['productionHints'] ?? ''}',
      styleSeedHints: '${json['styleSeedHints'] ?? ''}',
      musicBrainzTags: strList(json['musicBrainzTags']),
      sources: strList(json['sources']),
      geniusUrl: '${json['geniusUrl'] ?? ''}',
      geniusTitle: '${json['geniusTitle'] ?? ''}',
      audioProfile: audio,
      extractedAt: DateTime.tryParse('${json['extractedAt'] ?? ''}'),
    );
  }

  String encodePretty() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  static String fingerprint({
    required String artist,
    required String song,
    required String lyricsExcerpt,
  }) {
    final raw =
        '${artist.trim().toLowerCase()}|${song.trim().toLowerCase()}|${lyricsExcerpt.trim()}';
    // Lightweight stable fingerprint (not cryptographic).
    var hash = 0xcbf29ce484222325;
    for (final unit in raw.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}

/// Measured / catalog audio traits used as a Style baseline.
class AudioProfile {
  const AudioProfile({
    required this.source,
    this.trackTitle = '',
    this.trackArtist = '',
    this.albumTitle = '',
    this.bpm,
    this.durationSec,
    this.gainDb,
    this.key = '',
    this.mode = '',
    this.energy,
    this.danceability,
    this.valence,
    this.acousticness,
    this.instrumentalness,
    this.loudnessDb,
    this.notes = const [],
  });

  final String source; // deezer, spotify, …
  final String trackTitle;
  final String trackArtist;
  final String albumTitle;
  final double? bpm;
  final int? durationSec;
  final double? gainDb;
  final String key;
  final String mode;
  final double? energy;
  final double? danceability;
  final double? valence;
  final double? acousticness;
  final double? instrumentalness;
  final double? loudnessDb;
  final List<String> notes;

  bool get isEmpty =>
      bpm == null &&
      durationSec == null &&
      gainDb == null &&
      key.trim().isEmpty &&
      energy == null &&
      trackTitle.trim().isEmpty;

  bool get hasBpm => bpm != null && bpm! > 0;

  String get bpmLabel {
    if (!hasBpm) return '';
    final v = bpm!;
    return v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }

  String toPromptLines() {
    final lines = <String>[];
    if (trackArtist.isNotEmpty && trackTitle.isNotEmpty) {
      lines.add('- matched_track: $trackArtist — $trackTitle');
    }
    if (albumTitle.isNotEmpty) lines.add('- album: $albumTitle');
    if (hasBpm) lines.add('- bpm: $bpmLabel');
    if (durationSec != null && durationSec! > 0) {
      lines.add('- duration_sec: $durationSec');
    }
    if (gainDb != null) {
      lines.add('- replay_gain_db: ${gainDb!.toStringAsFixed(2)}');
    }
    if (key.trim().isNotEmpty) lines.add('- key: ${key.trim()}');
    if (mode.trim().isNotEmpty) lines.add('- mode: ${mode.trim()}');
    if (energy != null) lines.add('- energy: ${energy!.toStringAsFixed(2)}');
    if (danceability != null) {
      lines.add('- danceability: ${danceability!.toStringAsFixed(2)}');
    }
    if (valence != null) lines.add('- valence: ${valence!.toStringAsFixed(2)}');
    if (acousticness != null) {
      lines.add('- acousticness: ${acousticness!.toStringAsFixed(2)}');
    }
    if (instrumentalness != null) {
      lines.add('- instrumentalness: ${instrumentalness!.toStringAsFixed(2)}');
    }
    if (loudnessDb != null) {
      lines.add('- loudness_db: ${loudnessDb!.toStringAsFixed(2)}');
    }
    for (final n in notes) {
      if (n.trim().isNotEmpty) lines.add('- note: ${n.trim()}');
    }
    return lines.join('\n');
  }

  Map<String, dynamic> toJson() => {
        'source': source,
        'trackTitle': trackTitle,
        'trackArtist': trackArtist,
        'albumTitle': albumTitle,
        'bpm': bpm,
        'durationSec': durationSec,
        'gainDb': gainDb,
        'key': key,
        'mode': mode,
        'energy': energy,
        'danceability': danceability,
        'valence': valence,
        'acousticness': acousticness,
        'instrumentalness': instrumentalness,
        'loudnessDb': loudnessDb,
        'notes': notes,
      };

  factory AudioProfile.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v'.trim());
    }

    int? i(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.round();
      return int.tryParse('$v'.trim());
    }

    return AudioProfile(
      source: '${json['source'] ?? ''}',
      trackTitle: '${json['trackTitle'] ?? ''}',
      trackArtist: '${json['trackArtist'] ?? ''}',
      albumTitle: '${json['albumTitle'] ?? ''}',
      bpm: d(json['bpm']),
      durationSec: i(json['durationSec']),
      gainDb: d(json['gainDb']),
      key: '${json['key'] ?? ''}',
      mode: '${json['mode'] ?? ''}',
      energy: d(json['energy']),
      danceability: d(json['danceability']),
      valence: d(json['valence']),
      acousticness: d(json['acousticness']),
      instrumentalness: d(json['instrumentalness']),
      loudnessDb: d(json['loudnessDb']),
      notes: (json['notes'] is List)
          ? (json['notes'] as List).map((e) => '$e').toList()
          : const [],
    );
  }
}
