/// Shared title/artist matching for Inspiration DNA enrichment clients.
/// Prefer a miss over attaching the wrong song's metadata.
class TrackMatch {
  TrackMatch._();

  static String norm(String s) => s.toLowerCase().trim();

  /// True when [title] is the same song as [query] (exact, featured-suffix, or
  /// whole-token containment). Rejects substring traps like Fortunate/Unfortunate.
  static bool titleMatches(String title, String query) {
    final t = norm(title);
    final q = norm(query);
    if (t.isEmpty || q.isEmpty) return false;
    if (t == q) return true;
    // "Red (feat. X)", "Red - Live", "Red (Remix)"
    if (t.startsWith('$q ') ||
        t.startsWith('$q(') ||
        t.startsWith('$q -') ||
        t.startsWith('$q [')) {
      return true;
    }
    // Whole-token containment either way, but not bare substring.
    if (_tokenContains(t, q) && !_isSubstringTrap(t, q)) return true;
    return false;
  }

  /// Soft artist check: exact or contains (case-insensitive).
  static bool artistMatches(String artistName, String query) {
    final a = norm(artistName);
    final q = norm(query);
    if (a.isEmpty || q.isEmpty) return true; // no constraint
    return a == q || a.contains(q) || q.contains(a);
  }

  static bool _isSubstringTrap(String title, String query) {
    // e.g. query "Unfortunate", title "Fortunate"
    if (query.contains(title) && title.length >= 3 && query != title) {
      return true;
    }
    // e.g. query "Red", title "Everything I Need" — tokenContains false anyway
    return false;
  }

  static bool _tokenContains(String hay, String needle) {
    if (needle.isEmpty || hay.isEmpty) return false;
    if (hay == needle) return true;
    final pattern = RegExp(
      '(^|[^a-z0-9])${RegExp.escape(needle)}([^a-z0-9]|\$)',
    );
    return pattern.hasMatch(hay);
  }

  static bool isJunkCover(String blob) {
    final b = norm(blob);
    const bad = [
      'made famous',
      'as made famous',
      'karaoke',
      'tribute',
      'originally performed',
      'sound-alike',
      'instrumental cover',
      'in the style of',
      'as performed by',
    ];
    return bad.any(b.contains);
  }
}
