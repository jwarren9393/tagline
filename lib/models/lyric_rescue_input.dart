/// User paste of an existing Suno (or other) song for lyric rescue / remaster.
class LyricRescueInput {
  const LyricRescueInput({
    this.title = '',
    this.lyrics = '',
    this.stylePrompt = '',
    this.excludeStyles = '',
    this.creatorNotes = '',
  });

  final String title;
  final String lyrics;
  final String stylePrompt;
  final String excludeStyles;

  /// What you meant / felt when you made the song — intent the rewrite should honor.
  final String creatorNotes;

  bool get isValid => lyrics.trim().length >= 40;

  LyricRescueInput copyWith({
    String? title,
    String? lyrics,
    String? stylePrompt,
    String? excludeStyles,
    String? creatorNotes,
  }) {
    return LyricRescueInput(
      title: title ?? this.title,
      lyrics: lyrics ?? this.lyrics,
      stylePrompt: stylePrompt ?? this.stylePrompt,
      excludeStyles: excludeStyles ?? this.excludeStyles,
      creatorNotes: creatorNotes ?? this.creatorNotes,
    );
  }

  String toPromptBlock() {
    final buf = StringBuffer();
    buf.writeln('LYRIC RESCUE — rewrite an existing song for craft quality.');
    if (title.trim().isNotEmpty) {
      buf.writeln('TITLE: ${title.trim()}');
    }
    if (creatorNotes.trim().isNotEmpty) {
      buf.writeln('\nCREATOR INTENT / NOTES (honor these — this is the soul):');
      buf.writeln(creatorNotes.trim());
    }
    if (stylePrompt.trim().isNotEmpty) {
      buf.writeln('\nORIGINAL STYLE PROMPT (sonic baseline — keep feel, may polish):');
      buf.writeln(stylePrompt.trim());
    }
    if (excludeStyles.trim().isNotEmpty) {
      buf.writeln('\nORIGINAL EXCLUDE STYLES:');
      buf.writeln(excludeStyles.trim());
    }
    buf.writeln('\nORIGINAL LYRICS (fix craft problems; keep section skeleton + intent):');
    buf.writeln(lyrics.trim());
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'lyrics': lyrics,
        'stylePrompt': stylePrompt,
        'excludeStyles': excludeStyles,
        'creatorNotes': creatorNotes,
      };

  factory LyricRescueInput.fromJson(Map<String, dynamic> json) {
    return LyricRescueInput(
      title: '${json['title'] ?? ''}',
      lyrics: '${json['lyrics'] ?? ''}',
      stylePrompt: '${json['stylePrompt'] ?? ''}',
      excludeStyles: '${json['excludeStyles'] ?? ''}',
      creatorNotes: '${json['creatorNotes'] ?? ''}',
    );
  }
}
