import '../data/genre_templates.dart';
import 'inspiration_dna.dart';

/// User input for a generation session.
class SongIdea {
  const SongIdea({
    required this.rawIdea,
    this.genreId,
    this.moods = const [],
    this.constraints = '',
    this.referenceVibes = '',
    this.titleHint = '',
    this.inspirationArtist = '',
    this.inspirationSong = '',
    this.inspirationLyricsExcerpt = '',
    this.inspirationDna,
  });

  final String rawIdea;
  final String? genreId;
  final List<String> moods;
  final String constraints;
  final String referenceVibes;
  final String titleHint;

  /// Optional inspiration sources (artist / song / user-pasted excerpt).
  final String inspirationArtist;
  final String inspirationSong;
  final String inspirationLyricsExcerpt;
  final InspirationDna? inspirationDna;

  GenreTemplate? get genre => genreId == null ? null : genreById(genreId!);

  bool get hasInspirationSource =>
      inspirationArtist.trim().isNotEmpty ||
      inspirationSong.trim().isNotEmpty ||
      inspirationLyricsExcerpt.trim().isNotEmpty;

  String get inspirationFingerprint => InspirationDna.fingerprint(
        artist: inspirationArtist,
        song: inspirationSong,
        lyricsExcerpt: inspirationLyricsExcerpt,
      );

  bool get inspirationDnaIsFresh =>
      inspirationDna != null &&
      inspirationDna!.sourceFingerprint == inspirationFingerprint;

  SongIdea copyWith({
    String? rawIdea,
    String? genreId,
    List<String>? moods,
    String? constraints,
    String? referenceVibes,
    String? titleHint,
    String? inspirationArtist,
    String? inspirationSong,
    String? inspirationLyricsExcerpt,
    InspirationDna? inspirationDna,
    bool clearGenre = false,
    bool clearInspirationDna = false,
  }) {
    return SongIdea(
      rawIdea: rawIdea ?? this.rawIdea,
      genreId: clearGenre ? null : (genreId ?? this.genreId),
      moods: moods ?? this.moods,
      constraints: constraints ?? this.constraints,
      referenceVibes: referenceVibes ?? this.referenceVibes,
      titleHint: titleHint ?? this.titleHint,
      inspirationArtist: inspirationArtist ?? this.inspirationArtist,
      inspirationSong: inspirationSong ?? this.inspirationSong,
      inspirationLyricsExcerpt:
          inspirationLyricsExcerpt ?? this.inspirationLyricsExcerpt,
      inspirationDna: clearInspirationDna
          ? null
          : (inspirationDna ?? this.inspirationDna),
    );
  }

  String toPromptBlock() {
    final buf = StringBuffer();
    buf.writeln('SONG IDEA:');
    buf.writeln(rawIdea.trim());
    if (titleHint.trim().isNotEmpty) {
      buf.writeln('\nTITLE HINT: ${titleHint.trim()}');
    }
    if (genre != null) {
      buf.writeln('\nGENRE: ${genre!.label}');
      buf.writeln('SYLLABLE TARGETS: verse ${genre!.verseSyllables}, '
          'chorus ${genre!.chorusSyllables}');
      buf.writeln('SUGGESTED STRUCTURE: ${genre!.structureHint}');
      if (genre!.notes.isNotEmpty) {
        buf.writeln('GENRE NOTES: ${genre!.notes}');
      }
    }
    if (moods.isNotEmpty) {
      buf.writeln('\nMOODS: ${moods.join(', ')}');
    }
    if (referenceVibes.trim().isNotEmpty) {
      buf.writeln('\nREFERENCE VIBES (feel/energy only, do not copy lyrics): '
          '${referenceVibes.trim()}');
    }
    if (constraints.trim().isNotEmpty) {
      buf.writeln('\nCONSTRAINTS: ${constraints.trim()}');
    }
    if (inspirationDna != null && !inspirationDna!.isEmpty) {
      buf.writeln();
      buf.writeln(inspirationDna!.toPromptBlock());
    } else if (hasInspirationSource) {
      buf.writeln('\nINSPIRATION SOURCES (DNA not extracted yet — treat as vibe only):');
      if (inspirationArtist.trim().isNotEmpty) {
        buf.writeln('Artist: ${inspirationArtist.trim()}');
      }
      if (inspirationSong.trim().isNotEmpty) {
        buf.writeln('Song: ${inspirationSong.trim()}');
      }
      buf.writeln('Do not copy lyrics or distinctive phrases.');
    }
    return buf.toString();
  }

  bool get isValid => rawIdea.trim().length >= 8;

  Map<String, dynamic> toJson() => {
        'rawIdea': rawIdea,
        'genreId': genreId,
        'moods': moods,
        'constraints': constraints,
        'referenceVibes': referenceVibes,
        'titleHint': titleHint,
        'inspirationArtist': inspirationArtist,
        'inspirationSong': inspirationSong,
        'inspirationLyricsExcerpt': inspirationLyricsExcerpt,
        if (inspirationDna != null) 'inspirationDna': inspirationDna!.toJson(),
      };

  factory SongIdea.fromJson(Map<String, dynamic> json) {
    InspirationDna? dna;
    final rawDna = json['inspirationDna'];
    if (rawDna is Map) {
      dna = InspirationDna.fromJson(Map<String, dynamic>.from(rawDna));
    }
    return SongIdea(
      rawIdea: json['rawIdea'] as String? ?? '',
      genreId: json['genreId'] as String?,
      moods: (json['moods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      constraints: json['constraints'] as String? ?? '',
      referenceVibes: json['referenceVibes'] as String? ?? '',
      titleHint: json['titleHint'] as String? ?? '',
      inspirationArtist: json['inspirationArtist'] as String? ?? '',
      inspirationSong: json['inspirationSong'] as String? ?? '',
      inspirationLyricsExcerpt:
          json['inspirationLyricsExcerpt'] as String? ?? '',
      inspirationDna: dna,
    );
  }
}
