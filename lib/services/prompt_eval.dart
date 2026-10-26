import '../models/generation_result.dart';
import '../models/generation_session.dart';
import 'cliche_detector.dart';
import 'syllable_analyzer.dart';

/// Deterministic quality harness for Suno-ready lyrics + style.
///
/// Used after generation, in the results UI, and in unit tests with fixtures
/// so prompt changes can be scored without burning Suno credits.
class PromptEval {
  const PromptEval();

  EvalSummary evaluate({
    required String lyrics,
    required String style,
    String exclude = '',
  }) {
    final checks = <EvalCheck>[
      _hasStructureTags(lyrics),
      _chorusPresent(lyrics),
      _chorusRepeats(lyrics),
      _tagsOnOwnLines(lyrics),
      _noStoryInStyle(style),
      _noNegativesInStyle(style),
      _styleFrontLoadsGenre(style),
      _styleHasBpmOrTempoCue(style),
      _underCharBudgets(lyrics, style, exclude),
      _clicheDensity(lyrics),
      _syllableConsistency(lyrics),
      _conversationalLineLength(lyrics),
      _verseRhymePresence(lyrics),
    ];

    final maxScore = checks.fold<int>(0, (s, c) => s + c.weight);
    final score = checks.fold<int>(0, (s, c) => s + (c.passed ? c.weight : 0));

    return EvalSummary(
      score: score,
      maxScore: maxScore,
      checks: checks,
      ranAt: DateTime.now().toUtc(),
    );
  }

  EvalSummary evaluateResult(GenerationResult result) => evaluate(
        lyrics: result.lyrics,
        style: result.stylePrompt,
        exclude: result.excludeStyles,
      );

  EvalCheck _hasStructureTags(String lyrics) {
    final tags = RegExp(r'^\s*\[.+\]\s*$', multiLine: true).allMatches(lyrics);
    final ok = tags.length >= 3;
    return EvalCheck(
      id: 'structure_tags',
      label: 'Has multiple Suno structure tags',
      passed: ok,
      weight: 3,
      detail: ok ? '${tags.length} tags' : 'Need at least 3 section tags',
    );
  }

  EvalCheck _chorusPresent(String lyrics) {
    final ok = RegExp(r'^\s*\[Chorus', multiLine: true, caseSensitive: false)
        .hasMatch(lyrics);
    return EvalCheck(
      id: 'chorus_present',
      label: 'Includes a [Chorus]',
      passed: ok,
      weight: 2,
      detail: ok ? 'Found' : 'Missing [Chorus]',
    );
  }

  EvalCheck _chorusRepeats(String lyrics) {
    final bodies = _sectionBodies(lyrics, 'chorus');
    if (bodies.length < 2) {
      return const EvalCheck(
        id: 'chorus_repeat',
        label: 'Chorus repeats verbatim',
        passed: true,
        weight: 2,
        detail: 'Only one chorus (skipped)',
      );
    }
    // Compare sung lines only — parenthetical ad-libs may vary by chorus.
    final first = _normalizeSungSection(bodies.first);
    final allSame =
        bodies.every((b) => _normalizeSungSection(b) == first);
    return EvalCheck(
      id: 'chorus_repeat',
      label: 'Chorus repeats verbatim',
      passed: allSame,
      weight: 2,
      detail: allSame
          ? '${bodies.length} matching choruses (ad-libs ignored)'
          : 'Sung chorus text differs between appearances',
    );
  }

  EvalCheck _tagsOnOwnLines(String lyrics) {
    final bad = RegExp(r'\[[^\]]+\]\S').hasMatch(lyrics) ||
        RegExp(r'\S\[[^\]]+\]').hasMatch(lyrics);
    var shared = false;
    for (final line in lyrics.split('\n')) {
      final t = line.trim();
      if (t.contains('[') && t.contains(']') && !RegExp(r'^\[.+\]$').hasMatch(t)) {
        if (!RegExp(r'^\[.+:.+\]$').hasMatch(t)) {
          shared = true;
          break;
        }
      }
    }
    final ok = !bad && !shared;
    return EvalCheck(
      id: 'tags_own_lines',
      label: 'Structure tags on their own lines',
      passed: ok,
      weight: 2,
      detail: ok ? 'OK' : 'Tag appears inline with lyric text',
    );
  }

  EvalCheck _noStoryInStyle(String style) {
    final lower = style.toLowerCase();
    final storyHits = <String>[];
    // Do NOT flag bare "verse"/"chorus" — Style often says "choir on chorus".
    for (final term in [
      'about a ',
      'tells the story',
      'tell the story',
      'lyrics about',
      'song about',
      '[intro]',
      '[verse',
      '[chorus',
      '[bridge',
    ]) {
      if (lower.contains(term)) storyHits.add(term.trim());
    }
    if (RegExp(r'\bverse\s+and\s+chorus\b').hasMatch(lower)) {
      storyHits.add('verse and chorus');
    }
    final ok = storyHits.isEmpty;
    return EvalCheck(
      id: 'style_no_story',
      label: 'Style has no story / section tags',
      passed: ok,
      weight: 3,
      detail: ok ? 'OK' : 'Found: ${storyHits.join(', ')}',
    );
  }

  EvalCheck _noNegativesInStyle(String style) {
    final lower = style.toLowerCase();
    final hit = RegExp(r'\bno\s+[a-z]').hasMatch(lower) ||
        lower.contains('without ') ||
        lower.contains('avoid ') ||
        lower.contains("don't ");
    return EvalCheck(
      id: 'style_no_negatives',
      label: 'Negatives not inline in Style',
      passed: !hit,
      weight: 2,
      detail: hit ? 'Move negatives to Exclude Styles' : 'OK',
    );
  }

  EvalCheck _styleFrontLoadsGenre(String style) {
    final first = style.trim().split(RegExp(r'[,.]')).first.toLowerCase();
    final genreish = RegExp(
      r'\b(pop|rock|folk|country|hip-?hop|rap|r&b|soul|metal|jazz|blues|'
      r'electronic|synth|indie|ballad|punk|latin|reggaeton|edm|trap|ambient)\b',
    ).hasMatch(first);
    return EvalCheck(
      id: 'style_genre_first',
      label: 'Style front-loads genre/subgenre',
      passed: genreish,
      weight: 2,
      detail: genreish ? '“${first.trim()}”' : 'Lead with genre, not mood/story',
    );
  }

  EvalCheck _styleHasBpmOrTempoCue(String style) {
    final ok = RegExp(r'\b\d{2,3}\s*bpm\b', caseSensitive: false)
            .hasMatch(style) ||
        RegExp(
          r'\b(slow|midtempo|mid-tempo|uptempo|up-tempo|ballad tempo)\b',
          caseSensitive: false,
        ).hasMatch(style);
    return EvalCheck(
      id: 'style_tempo',
      label: 'Style includes BPM or tempo cue',
      passed: ok,
      weight: 1,
      detail: ok ? 'OK' : 'Add BPM or tempo descriptor',
    );
  }

  EvalCheck _underCharBudgets(String lyrics, String style, String exclude) {
    final ok = lyrics.length <= 4500 &&
        style.length <= 1000 &&
        exclude.length <= 1000;
    return EvalCheck(
      id: 'char_budgets',
      label: 'Under Suno character sweet spots',
      passed: ok,
      weight: 1,
      detail:
          'lyrics ${lyrics.length}/4500 · style ${style.length}/1000 · exclude ${exclude.length}/1000',
    );
  }

  EvalCheck _clicheDensity(String lyrics) {
    final hits = ClicheDetector.scan(lyrics);
    final lines = lyrics
        .split('\n')
        .where((l) => l.trim().isNotEmpty && !l.trim().startsWith('['))
        .length;
    final density = lines == 0 ? 0.0 : hits.length / lines;
    final ok = hits.length <= 2 && density <= 0.25;
    return EvalCheck(
      id: 'cliche_density',
      label: 'Low cliché density',
      passed: ok,
      weight: 3,
      detail: hits.isEmpty
          ? 'No known cliché hits'
          : '${hits.length} hit(s): ${hits.take(3).map((h) => h.term).join(', ')}',
    );
  }

  EvalCheck _syllableConsistency(String lyrics) {
    final feedback = SyllableAnalyzer.analyze(lyrics);
    final badSections =
        feedback.sectionSummaries.where((s) => s.isInconsistent).length;
    final longLines = feedback.syllableNotes
        .where((n) => n.contains('may rush'))
        .length;
    final ok = badSections == 0 && longLines <= 1;
    return EvalCheck(
      id: 'syllable_consistency',
      label: 'Syllable consistency within sections',
      passed: ok,
      weight: 2,
      detail: ok
          ? 'OK'
          : '$badSections inconsistent section(s), $longLines very long line(s)',
    );
  }

  EvalCheck _conversationalLineLength(String lyrics) {
    final lyricLines = lyrics.split('\n').where((l) {
      final t = l.trim();
      return t.isNotEmpty && !t.startsWith('[');
    });
    var long = 0;
    for (final line in lyricLines) {
      final cleaned = line.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
      if (cleaned.split(RegExp(r'\s+')).length > 14) long++;
    }
    final ok = long <= 2;
    return EvalCheck(
      id: 'line_length',
      label: 'Lines stay singably short',
      passed: ok,
      weight: 2,
      detail: ok ? 'OK' : '$long overly wordy line(s)',
    );
  }

  /// Orthographic end-rhyme heuristic on verse sections (AABB or ABAB).
  EvalCheck _verseRhymePresence(String lyrics) {
    final verses = [
      ..._sectionBodies(lyrics, 'verse'),
      ..._sectionBodies(lyrics, 'pre-chorus'),
      ..._sectionBodies(lyrics, 'prechorus'),
    ];
    if (verses.isEmpty) {
      return const EvalCheck(
        id: 'verse_rhyme',
        label: 'Verses show end rhyme',
        passed: true,
        weight: 2,
        detail: 'No verse sections (skipped)',
      );
    }

    var pairs = 0;
    var hits = 0;
    for (final body in verses) {
      final ends = body
          .split('\n')
          .map(_lineEndWord)
          .where((w) => w.isNotEmpty)
          .toList();
      if (ends.length < 2) continue;

      var aabbPairs = 0;
      var aabbHits = 0;
      for (var i = 0; i + 1 < ends.length; i += 2) {
        aabbPairs++;
        if (_endsRhyme(ends[i], ends[i + 1])) aabbHits++;
      }

      var ababPairs = 0;
      var ababHits = 0;
      for (var i = 0; i + 3 < ends.length; i += 4) {
        ababPairs += 2;
        if (_endsRhyme(ends[i], ends[i + 2])) ababHits++;
        if (_endsRhyme(ends[i + 1], ends[i + 3])) ababHits++;
      }

      final aabbRate = aabbPairs == 0 ? 0.0 : aabbHits / aabbPairs;
      final ababRate = ababPairs == 0 ? 0.0 : ababHits / ababPairs;
      if (ababPairs > 0 && ababRate > aabbRate) {
        pairs += ababPairs;
        hits += ababHits;
      } else {
        pairs += aabbPairs;
        hits += aabbHits;
      }
    }

    final rate = pairs == 0 ? 1.0 : hits / pairs;
    final ok = rate >= 0.45;
    return EvalCheck(
      id: 'verse_rhyme',
      label: 'Verses show end rhyme',
      passed: ok,
      weight: 2,
      detail: pairs == 0
          ? 'Insufficient lines'
          : '${(rate * 100).round()}% rhyming pairs ($hits/$pairs)',
    );
  }

  List<String> _sectionBodies(String lyrics, String sectionName) {
    final lines = lyrics.split('\n');
    final bodies = <String>[];
    final tagRe = RegExp(r'^\s*\[(.+?)\]\s*$');
    StringBuffer? buf;
    bool capture = false;

    void flush() {
      if (capture && buf != null) {
        bodies.add(buf.toString().trim());
      }
      buf = null;
      capture = false;
    }

    for (final line in lines) {
      final m = tagRe.firstMatch(line);
      if (m != null) {
        flush();
        final name = m.group(1)!.toLowerCase();
        capture = name.startsWith(sectionName.toLowerCase());
        if (capture) buf = StringBuffer();
        continue;
      }
      if (capture) {
        buf!.writeln(line);
      }
    }
    flush();
    return bodies;
  }

  /// Sung chorus only: drop parentheticals and ad-lib-only lines.
  String _normalizeSungSection(String body) {
    return body
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'\([^)]*\)'), '').trim())
        .where((l) => l.isNotEmpty)
        .join('\n')
        .toLowerCase();
  }

  String _lineEndWord(String line) {
    var cleaned = line.replaceAll(RegExp(r'\([^)]*\)'), ' ').trim();
    if (cleaned.isEmpty || cleaned.startsWith('[')) return '';
    cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-z0-9\s\-]'), '');
    final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    return parts.last.toLowerCase();
  }

  bool _endsRhyme(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    final ea = _rhymeKey(a);
    final eb = _rhymeKey(b);
    if (ea.isEmpty || eb.isEmpty) return false;
    if (ea == eb) return true;
    // Soft orthographic near-rhyme: last 2 chars of raw ending match.
    if (ea.length >= 2 &&
        eb.length >= 2 &&
        ea.substring(ea.length - 2) == eb.substring(eb.length - 2)) {
      return true;
    }
    return false;
  }

  /// Rough rhyme key: last-vowel ending folded into common spelling families.
  String _rhymeKey(String word) {
    var w = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (w.isEmpty) return '';
    // Only strip plural/past when the stem stays long enough.
    for (final suf in ['ed', 'er', 'est', 'ly', 's']) {
      if (w.length > suf.length + 3 && w.endsWith(suf)) {
        w = w.substring(0, w.length - suf.length);
        break;
      }
    }
    // Prefer last 3 letters — more stable than pure vowel-coda for "there"/"chair".
    var ending = w.length <= 3 ? w : w.substring(w.length - 3);
    return _foldRhymeFamily(ending);
  }

  String _foldRhymeFamily(String ending) {
    const families = <List<String>>[
      ['air', 'are', 'ear', 'ere', 'eir'],
      ['ight', 'ite', 'yte'],
      ['oor', 'ore', 'our', 'aure'],
      ['ame', 'aim'],
      ['ine', 'ign', 'yme'],
      ['all', 'awl', 'aul'],
      ['ay', 'ey', 'eigh'],
      ['oh', 'ow', 'oe', 'o'],
      ['ome', 'oam', 'own', 'one'], // home / alone / own — allow slant
      ['oo', 'ue', 'ew', 'u'],
      ['ack', 'ak'],
      ['ick', 'ick'],
      ['ing', 'in'],
    ];
    for (final family in families) {
      for (final form in family) {
        if (ending == form || ending.endsWith(form)) return family.first;
      }
    }
    return ending;
  }
}
