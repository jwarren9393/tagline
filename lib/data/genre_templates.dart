/// Genre templates that seed style prompts and syllable targets.
library;

class GenreTemplate {
  const GenreTemplate({
    required this.id,
    required this.label,
    required this.styleSeed,
    required this.excludeSeed,
    required this.structureHint,
    this.verseSyllables = '6-10',
    this.chorusSyllables = '4-8',
    this.notes = '',
  });

  final String id;
  final String label;

  /// Front-loaded style fragment (genre first).
  final String styleSeed;

  /// Suggested exclude styles.
  final String excludeSeed;

  /// Suggested section order for this genre.
  final String structureHint;

  final String verseSyllables;
  final String chorusSyllables;
  final String notes;
}

const List<GenreTemplate> kGenreTemplates = [
  GenreTemplate(
    id: 'indie_folk',
    label: 'Indie Folk',
    styleSeed:
        'indie folk, intimate acoustic storytelling, warm fingerpicked guitar, '
        'soft male or female vocal with close-mic breath, light brushes and upright bass, '
        'organic room production, 1980s–present indie folk feel, 88 BPM',
    excludeSeed: 'EDM, autotune, trap drums, stadium rock, metal',
    structureHint: '[Intro] [Verse 1] [Chorus] [Verse 2] [Chorus] [Bridge] [Chorus] [Outro]',
    verseSyllables: '7-10',
    chorusSyllables: '5-8',
    notes: 'Conversational verses; chorus short and repeatable.',
  ),
  GenreTemplate(
    id: 'pop',
    label: 'Pop',
    styleSeed:
        'modern pop, bright midtempo hook-driven, polished lead vocal with light doubles, '
        'punchy kick and crisp snare, synth bass, clean electric guitar stabs, '
        'radio-ready glossy mix, 2020s production, 118 BPM',
    excludeSeed: 'metal, harsh distortion, lo-fi mud, spoken word',
    structureHint:
        '[Intro] [Verse 1] [Pre-Chorus] [Chorus] [Verse 2] [Pre-Chorus] [Chorus] [Bridge] [Chorus] [Outro]',
    verseSyllables: '6-10',
    chorusSyllables: '4-7',
    notes: 'Front-load the hook; end chorus lines on open vowels when possible.',
  ),
  GenreTemplate(
    id: 'rnb',
    label: 'R&B / Soul',
    styleSeed:
        'contemporary R&B, smooth sensual midtempo, velvet lead vocal with melisma and soft ad-libs, '
        'warm Rhodes, deep sub bass, sparse trap-influenced drums, atmospheric pads, '
        'intimate late-night production, 92 BPM',
    excludeSeed: 'punk, metal, country twang, EDM drops',
    structureHint:
        '[Intro] [Verse 1] [Pre-Chorus] [Chorus] [Verse 2] [Chorus] [Bridge] [Chorus] [Outro]',
    verseSyllables: '6-11',
    chorusSyllables: '4-8',
    notes: 'Space for melisma; ad-libs in parentheses.',
  ),
  GenreTemplate(
    id: 'hip_hop',
    label: 'Hip-Hop / Rap',
    styleSeed:
        'modern hip-hop, hard-hitting boom-bap/trap hybrid, confident rhythmic male vocal, '
        '808 bass, crisp hi-hats, sparse piano loop, dark atmospheric pads, '
        'punchy dry mix with tight low end, 140 BPM',
    excludeSeed: 'opera, acoustic folk, metal scream, EDM festival drop',
    structureHint: '[Intro] [Verse 1] [Chorus] [Verse 2] [Chorus] [Bridge] [Verse 3] [Chorus] [Outro]',
    verseSyllables: '10-16',
    chorusSyllables: '5-9',
    notes: 'Higher syllable density in verses; chorus stays chantable.',
  ),
  GenreTemplate(
    id: 'rock',
    label: 'Rock / Alt Rock',
    styleSeed:
        'alternative rock, driving midtempo grit, raw passionate lead vocal, '
        'distorted rhythm guitars, melodic lead fills, tight live drums, bass that locks with kick, '
        'live-room energy with modern polish, 128 BPM',
    excludeSeed: 'trap 808s, autotune heavy pop, lo-fi bedroom',
    structureHint:
        '[Intro] [Verse 1] [Pre-Chorus] [Chorus] [Verse 2] [Chorus] [Solo] [Bridge] [Chorus] [Outro]',
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'country',
    label: 'Country',
    styleSeed:
        'modern country, storytelling with twang, warm earnest lead vocal, '
        'acoustic guitar, pedal steel, clean electric fills, live drums with shuffle feel, '
        'radio country polish, 96 BPM',
    excludeSeed: 'EDM, trap, metal, heavy autotune',
    structureHint:
        '[Intro] [Verse 1] [Chorus] [Verse 2] [Chorus] [Bridge] [Chorus] [Outro]',
    verseSyllables: '7-11',
    chorusSyllables: '5-8',
    notes: 'Concrete place/object details; conversational drawl-friendly lines.',
  ),
  GenreTemplate(
    id: 'electronic',
    label: 'Electronic / Synth-Pop',
    styleSeed:
        'synth-pop electronic, glassy arpeggios and pulsing bass, clear emotive lead vocal, '
        'sidechained pads, crisp electronic drums, neon-adjacent but clean production, '
        'danceable midtempo, 120 BPM',
    excludeSeed: 'acoustic folk, live garage rock, metal',
    structureHint:
        '[Intro] [Verse 1] [Build] [Chorus] [Verse 2] [Build] [Chorus] [Bridge] [Drop] [Chorus] [Outro]',
    verseSyllables: '6-10',
    chorusSyllables: '4-7',
  ),
  GenreTemplate(
    id: 'ballad',
    label: 'Ballad',
    styleSeed:
        'emotional piano ballad, intimate sparse arrangement, vulnerable close-mic vocal, '
        'soft strings enter mid-song, gentle dynamics swell, cinematic but restrained production, 72 BPM',
    excludeSeed: 'EDM, trap drums, aggressive rock, party vibes',
    structureHint:
        '[Intro] [Verse 1] [Chorus] [Verse 2] [Chorus] [Bridge] [Chorus] [Outro]',
    verseSyllables: '6-10',
    chorusSyllables: '5-8',
    notes: 'Leave space; avoid overwriting every beat.',
  ),
  GenreTemplate(
    id: 'metal',
    label: 'Metal / Hard Rock',
    styleSeed:
        'modern metal, aggressive double-kick drive, powerful belted or harsh-capable vocal, '
        'tight palm-muted guitars, thunderous bass, precise drums, polished heavy mix, 140 BPM',
    excludeSeed: 'acoustic lullaby, soft jazz, trap pop',
    structureHint:
        '[Intro] [Verse 1] [Pre-Chorus] [Chorus] [Verse 2] [Chorus] [Bridge] [Solo] [Chorus] [Outro]',
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'latin',
    label: 'Latin / Reggaeton',
    styleSeed:
        'modern reggaeton / Latin pop, dembow groove, smooth bilingual-capable vocal, '
        'bright synths, syncopated percussion, warm bass, club-ready polish, 95 BPM',
    excludeSeed: 'metal, country steel, orchestral classical',
    structureHint:
        '[Intro] [Verse 1] [Pre-Chorus] [Chorus] [Verse 2] [Chorus] [Bridge] [Chorus] [Outro]',
    verseSyllables: '6-10',
    chorusSyllables: '4-7',
  ),
];

GenreTemplate? genreById(String id) {
  for (final g in kGenreTemplates) {
    if (g.id == id) return g;
  }
  return null;
}

const List<String> kMoodOptions = [
  'Intimate',
  'Melancholy',
  'Hopeful',
  'Angry',
  'Playful',
  'Dark',
  'Nostalgic',
  'Romantic',
  'Defiant',
  'Dreamy',
  'Urgent',
  'Bittersweet',
];
