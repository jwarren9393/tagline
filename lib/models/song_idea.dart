import '../data/genre_templates.dart';

/// User input for a generation session.
class SongIdea {
  const SongIdea({
    required this.rawIdea,
    this.genreId,
    this.moods = const [],
    this.constraints = '',
    this.referenceVibes = '',
    this.titleHint = '',
  });

  final String rawIdea;
  final String? genreId;
  final List<String> moods;
  final String constraints;
  final String referenceVibes;
  final String titleHint;

  GenreTemplate? get genre => genreId == null ? null : genreById(genreId!);

  SongIdea copyWith({
    String? rawIdea,
    String? genreId,
    List<String>? moods,
    String? constraints,
    String? referenceVibes,
    String? titleHint,
    bool clearGenre = false,
  }) {
    return SongIdea(
      rawIdea: rawIdea ?? this.rawIdea,
      genreId: clearGenre ? null : (genreId ?? this.genreId),
      moods: moods ?? this.moods,
      constraints: constraints ?? this.constraints,
      referenceVibes: referenceVibes ?? this.referenceVibes,
      titleHint: titleHint ?? this.titleHint,
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
    return buf.toString();
  }

  bool get isValid => rawIdea.trim().length >= 8;
}
