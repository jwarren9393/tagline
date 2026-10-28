/// User paste of an existing Suno (or other) song for lyric rescue / remaster.
class LyricRescueInput {
  const LyricRescueInput({
    this.title = '',
    this.lyrics = '',
    this.stylePrompt = '',
    this.excludeStyles = '',
    this.creatorNotes = '',
    this.preserveStructureStrictly = true,
    this.tightenVerseLength = false,
    this.rewriteChorus = false,
  });

  final String title;
  final String lyrics;
  final String stylePrompt;
  final String excludeStyles;

  /// What you meant / felt when you made the song — intent the rewrite should honor.
  final String creatorNotes;

  /// Keep section skeleton and approximate section lengths (default remaster behavior).
  final bool preserveStructureStrictly;

  /// Aim for shorter, more singable verse lines (~6–8 syllables where natural).
  final bool tightenVerseLength;

  /// Replace the original chorus with a stronger, concrete, Suno-friendly hook.
  final bool rewriteChorus;

  bool get isValid => lyrics.trim().length >= 40;

  /// Human-readable labels for active (non-default-only) + always-visible constraints.
  List<String> get activeConstraintLabels {
    final labels = <String>[];
    if (preserveStructureStrictly) {
      labels.add('Preserve structure');
    } else {
      labels.add('Flexible structure');
    }
    if (tightenVerseLength) labels.add('Tighten verses');
    if (rewriteChorus) labels.add('Rewrite chorus');
    return labels;
  }

  LyricRescueInput copyWith({
    String? title,
    String? lyrics,
    String? stylePrompt,
    String? excludeStyles,
    String? creatorNotes,
    bool? preserveStructureStrictly,
    bool? tightenVerseLength,
    bool? rewriteChorus,
  }) {
    return LyricRescueInput(
      title: title ?? this.title,
      lyrics: lyrics ?? this.lyrics,
      stylePrompt: stylePrompt ?? this.stylePrompt,
      excludeStyles: excludeStyles ?? this.excludeStyles,
      creatorNotes: creatorNotes ?? this.creatorNotes,
      preserveStructureStrictly:
          preserveStructureStrictly ?? this.preserveStructureStrictly,
      tightenVerseLength: tightenVerseLength ?? this.tightenVerseLength,
      rewriteChorus: rewriteChorus ?? this.rewriteChorus,
    );
  }

  String toPromptBlock() {
    final buf = StringBuffer();
    buf.writeln('LYRIC RESCUE — rewrite an existing song for craft quality.');
    if (title.trim().isNotEmpty) {
      buf.writeln('TITLE: ${title.trim()}');
    }
    buf.writeln();
    buf.writeln(constraintsPromptBlock());
    if (creatorNotes.trim().isNotEmpty) {
      buf.writeln('\nCREATOR INTENT / NOTES (honor these — this is the soul):');
      buf.writeln(creatorNotes.trim());
    }
    if (stylePrompt.trim().isNotEmpty) {
      buf.writeln(
          '\nORIGINAL STYLE PROMPT (sonic baseline — keep feel, may polish):');
      buf.writeln(stylePrompt.trim());
    }
    if (excludeStyles.trim().isNotEmpty) {
      buf.writeln('\nORIGINAL EXCLUDE STYLES:');
      buf.writeln(excludeStyles.trim());
    }
    buf.writeln(
        '\nORIGINAL LYRICS (fix craft problems; apply ACTIVE RESCUE CONSTRAINTS):');
    buf.writeln(lyrics.trim());
    return buf.toString();
  }

  /// Explicit constraint block injected into diagnose / rewrite / optimize prompts.
  String constraintsPromptBlock() {
    final buf = StringBuffer()
      ..writeln('ACTIVE RESCUE CONSTRAINTS (mandatory):');
    if (preserveStructureStrictly) {
      buf.writeln(
        '- PRESERVE STRUCTURE STRICTLY: keep the same section tags/order and '
        'approximately the same line count per section. Remaster words, do not '
        'collapse or invent a new form.',
      );
    } else {
      buf.writeln(
        '- FLEXIBLE STRUCTURE: you may trim or reshape sections if craft improves, '
        'but keep the song recognizable (same spine / POV / emotional arc).',
      );
    }
    if (tightenVerseLength) {
      buf.writeln(
        '- TIGHTEN VERSE LENGTH: compress verse (and pre-chorus) lines toward '
        '~6–8 syllables where natural; even meter within each section. Prefer '
        'fewer words over padded talk. If PRESERVE STRUCTURE is also on, keep '
        'roughly the same number of lines but make each line shorter/punchier.',
      );
    } else {
      buf.writeln(
        '- VERSE LENGTH: match the original verse density unless a line is '
        'obviously padded; do not inflate.',
      );
    }
    if (rewriteChorus) {
      buf.writeln(
        '- REWRITE CHORUS: replace the original chorus with a stronger, concrete, '
        'Suno-friendly hook (short, repeatable, open vowels OK). Keep emotional '
        'thesis / creator intent, but do NOT protect cliché phoenix/ashes stacks '
        'or synonym lists. All chorus repeats must match verbatim (ad-libs may vary).',
      );
    } else {
      buf.writeln(
        '- PROTECT CHORUS (default): keep or lightly sharpen a strong original '
        'hook if it is distinctive and not pure cliché; only rewrite if it is '
        'unusable AI pastiche.',
      );
    }
    return buf.toString().trimRight();
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'lyrics': lyrics,
        'stylePrompt': stylePrompt,
        'excludeStyles': excludeStyles,
        'creatorNotes': creatorNotes,
        'preserveStructureStrictly': preserveStructureStrictly,
        'tightenVerseLength': tightenVerseLength,
        'rewriteChorus': rewriteChorus,
      };

  factory LyricRescueInput.fromJson(Map<String, dynamic> json) {
    bool flag(String key, {bool fallback = false}) {
      final v = json[key];
      if (v is bool) return v;
      if (v == null) return fallback;
      return '$v'.toLowerCase() == 'true';
    }

    return LyricRescueInput(
      title: '${json['title'] ?? ''}',
      lyrics: '${json['lyrics'] ?? ''}',
      stylePrompt: '${json['stylePrompt'] ?? ''}',
      excludeStyles: '${json['excludeStyles'] ?? ''}',
      creatorNotes: '${json['creatorNotes'] ?? ''}',
      preserveStructureStrictly:
          flag('preserveStructureStrictly', fallback: true),
      tightenVerseLength: flag('tightenVerseLength'),
      rewriteChorus: flag('rewriteChorus'),
    );
  }
}
