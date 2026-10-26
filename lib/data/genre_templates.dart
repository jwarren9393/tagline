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

const _v1c =
    '[Intro] [Verse 1] [Chorus] [Verse 2] [Chorus] [Bridge] [Chorus] [Outro]';
const _v1pc =
    '[Intro] [Verse 1] [Pre-Chorus] [Chorus] [Verse 2] [Pre-Chorus] [Chorus] [Bridge] [Chorus] [Outro]';

const List<GenreTemplate> kGenreTemplates = [
  GenreTemplate(
    id: 'afrobeats',
    label: 'Afrobeats',
    styleSeed:
        'afrobeats, sunny midtempo groove, melodic male or female vocal with light ad-libs, '
        'syncopated percussion, warm bass, bright guitar and keys, dancefloor polish, 105 BPM',
    excludeSeed: 'metal, country steel, orchestral classical, trap murk',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'ambient',
    label: 'Ambient / Atmospheric',
    styleSeed:
        'ambient atmospheric, spacious pads and soft textures, breathy intimate vocal, '
        'minimal pulse, washed reverb, cinematic but quiet, 70 BPM',
    excludeSeed: 'trap drums, metal, stadium rock, shout vocals',
    structureHint: _v1c,
    verseSyllables: '5-9',
    chorusSyllables: '4-7',
    notes: 'Leave air; short lines.',
  ),
  GenreTemplate(
    id: 'americana',
    label: 'Americana',
    styleSeed:
        'americana roots, dusty storytelling, warm earnest vocal, acoustic guitar, '
        'harmonica or pedal steel accents, live drums with soft shuffle, organic room, 92 BPM',
    excludeSeed: 'EDM, trap, autotune pop, metal',
    structureHint: _v1c,
    verseSyllables: '7-11',
    chorusSyllables: '5-8',
  ),
  GenreTemplate(
    id: 'ballad',
    label: 'Ballad',
    styleSeed:
        'emotional piano ballad, intimate sparse arrangement, vulnerable close-mic vocal, '
        'soft strings enter mid-song, gentle dynamics swell, cinematic but restrained production, 72 BPM',
    excludeSeed: 'EDM, trap drums, aggressive rock, party vibes',
    structureHint: _v1c,
    verseSyllables: '6-10',
    chorusSyllables: '5-8',
    notes: 'Leave space; avoid overwriting every beat.',
  ),
  GenreTemplate(
    id: 'bluegrass',
    label: 'Bluegrass',
    styleSeed:
        'bluegrass, bright acoustic drive, clear high-lonesome or warm lead vocal, '
        'banjo, mandolin, fiddle, upright bass, tight acoustic ensemble, 130 BPM',
    excludeSeed: 'EDM, trap, metal, heavy autotune',
    structureHint: _v1c,
    verseSyllables: '7-12',
    chorusSyllables: '5-9',
  ),
  GenreTemplate(
    id: 'blues',
    label: 'Blues',
    styleSeed:
        'electric blues, soulful grit, expressive lead vocal with bends and ache, '
        'overdriven guitar, Hammond organ, swinging drums, warm tube amp tone, 84 BPM',
    excludeSeed: 'EDM drops, trap hats, glossy teen pop',
    structureHint: _v1c,
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'bossa_nova',
    label: 'Bossa Nova',
    styleSeed:
        'bossa nova, soft swinging groove, intimate breathy vocal, nylon guitar, '
        'light brushed drums, warm upright bass, late-night lounge polish, 120 BPM',
    excludeSeed: 'metal, trap, harsh rock, stadium anthems',
    structureHint: _v1c,
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'christian_worship',
    label: 'Christian / Worship',
    styleSeed:
        'modern worship, wide emotional lift, sincere anthemic vocal, piano and pads, '
        'building drums, ambient electric guitar, church-arena reverb, 74 BPM',
    excludeSeed: 'trap smut, metal scream, comedy novelty',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'classic_rock',
    label: 'Classic Rock',
    styleSeed:
        'classic rock, swaggering midtempo, powerful belted vocal, crunchy rhythm guitars, '
        'melodic solos, big live drums, analog-era polish, 120 BPM',
    excludeSeed: 'trap 808s, hyperpop glitch, whisper folk',
    structureHint: _v1pc,
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
    structureHint: _v1c,
    verseSyllables: '7-11',
    chorusSyllables: '5-8',
    notes: 'Concrete place/object details; conversational drawl-friendly lines.',
  ),
  GenreTemplate(
    id: 'country_pop',
    label: 'Country Pop',
    styleSeed:
        'country pop, bright radio hook, polished vocal with light twang, '
        'acoustic and electric blend, snappy drums, crossover polish, 110 BPM',
    excludeSeed: 'metal, trap murk, lo-fi bedroom',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-7',
  ),
  GenreTemplate(
    id: 'dancehall',
    label: 'Dancehall',
    styleSeed:
        'dancehall, bouncing riddim, charismatic toasting-capable vocal, '
        'deep bass, syncopated drums, bright synth stabs, club energy, 100 BPM',
    excludeSeed: 'orchestral classical, acoustic folk ballad, metal',
    structureHint: _v1c,
    verseSyllables: '6-12',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'disco',
    label: 'Disco / Nu-Disco',
    styleSeed:
        'nu-disco, four-on-the-floor glitter, confident funky vocal, '
        'wah guitar, lush strings or synths, punchy kick, dancefloor sheen, 118 BPM',
    excludeSeed: 'doom metal, whisper folk, sad ballad',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-7',
  ),
  GenreTemplate(
    id: 'drill',
    label: 'Drill',
    styleSeed:
        'UK/US drill hybrid, dark sliding 808s, cold confident vocal, '
        'sparse eerie melody loop, skittering hi-hats, stark mix, 140 BPM',
    excludeSeed: 'acoustic folk, broadway, soft jazz',
    structureHint:
        '[Intro] [Verse 1] [Chorus] [Verse 2] [Chorus] [Bridge] [Verse 3] [Chorus] [Outro]',
    verseSyllables: '10-16',
    chorusSyllables: '5-9',
  ),
  GenreTemplate(
    id: 'drum_and_bass',
    label: 'Drum & Bass',
    styleSeed:
        'drum and bass, rolling breakbeats, energetic vocal chop or sung hook, '
        'deep sub bass, atmospheric pads, club-ready pressure, 174 BPM',
    excludeSeed: 'slow ballad, country steel, acoustic lullaby',
    structureHint:
        '[Intro] [Verse 1] [Build] [Drop] [Verse 2] [Build] [Drop] [Bridge] [Drop] [Outro]',
    verseSyllables: '6-10',
    chorusSyllables: '4-7',
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
    id: 'emo',
    label: 'Emo / Pop-Punk',
    styleSeed:
        'emo pop-punk, urgent emotional vocal, crunchy power chords, '
        'driving drums, melodic hooks, early-2000s energy with modern polish, 160 BPM',
    excludeSeed: 'trap, smooth jazz, ambient drone',
    structureHint: _v1pc,
    verseSyllables: '6-11',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'folk',
    label: 'Folk',
    styleSeed:
        'traditional folk, clear storytelling vocal, acoustic guitar and light harmony, '
        'minimal percussion or none, intimate wooden-room tone, 90 BPM',
    excludeSeed: 'EDM, trap, metal, heavy autotune',
    structureHint: _v1c,
    verseSyllables: '7-11',
    chorusSyllables: '5-8',
  ),
  GenreTemplate(
    id: 'funk',
    label: 'Funk',
    styleSeed:
        'classic funk, pocket groove, charismatic rhythmic vocal, '
        'slap or tight bass, syncopated drums, clean rhythm guitar chops, 108 BPM',
    excludeSeed: 'doom metal, whispered indie, ambient wash',
    structureHint: _v1c,
    verseSyllables: '6-12',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'gospel',
    label: 'Gospel',
    styleSeed:
        'gospel soul, powerful lead with choir call-and-response, Hammond organ, '
        'piano, swinging drums, church-house lift, 78 BPM',
    excludeSeed: 'trap smut, metal scream, icy techno',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'grunge',
    label: 'Grunge',
    styleSeed:
        'grunge alt rock, raw sandpaper vocal, thick distorted guitars, '
        'heavy drums, muddy-but-powerful 90s Seattle grit, 110 BPM',
    excludeSeed: 'glossy teen pop, tropical house, autotune glitter',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'house',
    label: 'House',
    styleSeed:
        'deep house / progressive house, hypnotic four-on-the-floor, soulful or airy vocal, '
        'warm bass, filtered pads, club reverb, 122 BPM',
    excludeSeed: 'acoustic ballad, metal, country twang',
    structureHint:
        '[Intro] [Verse 1] [Build] [Chorus] [Verse 2] [Build] [Chorus] [Breakdown] [Chorus] [Outro]',
    verseSyllables: '5-9',
    chorusSyllables: '3-7',
  ),
  GenreTemplate(
    id: 'hyperpop',
    label: 'Hyperpop',
    styleSeed:
        'hyperpop, maximal glitchy energy, processed emotive vocal, '
        'pitched FX, crunchy synths, abrupt switches, internet-native chaos, 150 BPM',
    excludeSeed: 'traditional bluegrass, opera, soft jazz',
    structureHint: _v1pc,
    verseSyllables: '5-10',
    chorusSyllables: '3-7',
  ),
  GenreTemplate(
    id: 'indie_folk',
    label: 'Indie Folk',
    styleSeed:
        'indie folk, intimate acoustic storytelling, warm fingerpicked guitar, '
        'soft male or female vocal with close-mic breath, light brushes and upright bass, '
        'organic room production, 1980s–present indie folk feel, 88 BPM',
    excludeSeed: 'EDM, autotune, trap drums, stadium rock, metal',
    structureHint: _v1c,
    verseSyllables: '7-10',
    chorusSyllables: '5-8',
    notes: 'Conversational verses; chorus short and repeatable.',
  ),
  GenreTemplate(
    id: 'indie_pop',
    label: 'Indie Pop',
    styleSeed:
        'indie pop, bright bittersweet hooks, clear conversational vocal, '
        'jangly guitars or soft synths, tight drums, DIY-to-radio polish, 112 BPM',
    excludeSeed: 'metal scream, drill, deathcore',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-7',
  ),
  GenreTemplate(
    id: 'indie_rock',
    label: 'Indie Rock',
    styleSeed:
        'indie rock, angular midtempo energy, distinctive lead vocal, '
        'crunchy or chiming guitars, live drums, garage-to-studio polish, 126 BPM',
    excludeSeed: 'trap 808s, orchestral broadway, smooth R&B gloss',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'jazz',
    label: 'Jazz / Vocal Jazz',
    styleSeed:
        'vocal jazz, swinging or ballad feel, nuanced phrasing vocal, '
        'piano trio or small combo, brushed drums, warm upright bass, smoky club, 96 BPM',
    excludeSeed: 'trap, metal, EDM festival drop',
    structureHint: _v1c,
    verseSyllables: '6-11',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'kpop',
    label: 'K-Pop',
    styleSeed:
        'K-pop, glossy high-energy hook machine, bright processed vocals with stacks, '
        'hybrid EDM-pop production, crisp percussion, maximal chorus lift, 128 BPM',
    excludeSeed: 'lo-fi folk, doom metal, raw field recording',
    structureHint: _v1pc,
    verseSyllables: '5-10',
    chorusSyllables: '3-7',
  ),
  GenreTemplate(
    id: 'latin',
    label: 'Latin / Reggaeton',
    styleSeed:
        'modern reggaeton / Latin pop, dembow groove, smooth bilingual-capable vocal, '
        'bright synths, syncopated percussion, warm bass, club-ready polish, 95 BPM',
    excludeSeed: 'metal, country steel, orchestral classical',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-7',
  ),
  GenreTemplate(
    id: 'lofi',
    label: 'Lo-Fi / Chillhop',
    styleSeed:
        'lo-fi hip-hop chill, dusty vinyl texture, soft spoken or mellow sung vocal, '
        'muted keys, soft drums, rainy-window vibe, 85 BPM',
    excludeSeed: 'stadium rock, metal, harsh EDM drops',
    structureHint: _v1c,
    verseSyllables: '5-9',
    chorusSyllables: '4-7',
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
    id: 'metalcore',
    label: 'Metalcore',
    styleSeed:
        'metalcore, breakdown-ready aggression, clean/harsh vocal contrast, '
        'chugging guitars, double-kick, modern polished heavy mix, 150 BPM',
    excludeSeed: 'bossa nova, soft jazz, acoustic lullaby',
    structureHint:
        '[Intro] [Verse 1] [Chorus] [Verse 2] [Chorus] [Breakdown] [Bridge] [Chorus] [Outro]',
    verseSyllables: '6-11',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'new_wave',
    label: 'New Wave',
    styleSeed:
        'new wave, angular 80s sheen, cool emotive vocal, chorus guitars, '
        'synth bass, tight drums, neon retro polish, 124 BPM',
    excludeSeed: 'trap murk, bluegrass, doom metal',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-7',
  ),
  GenreTemplate(
    id: 'philly_soul',
    label: 'Philly / Classic Soul',
    styleSeed:
        'classic soul, lush strings and horns, rich emotive lead vocal, '
        'warm bass, elegant drums, 1970s polish with modern clarity, 88 BPM',
    excludeSeed: 'hyperpop glitch, metal, drill',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'pop',
    label: 'Pop',
    styleSeed:
        'modern pop, bright midtempo hook-driven, polished lead vocal with light doubles, '
        'punchy kick and crisp snare, synth bass, clean electric guitar stabs, '
        'radio-ready glossy mix, 2020s production, 118 BPM',
    excludeSeed: 'metal, harsh distortion, lo-fi mud, spoken word',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-7',
    notes: 'Front-load the hook; end chorus lines on open vowels when possible.',
  ),
  GenreTemplate(
    id: 'pop_rock',
    label: 'Pop Rock',
    styleSeed:
        'pop rock, big sing-along chorus, clear powerful vocal, '
        'driving guitars, arena-ready drums, radio polish, 128 BPM',
    excludeSeed: 'lo-fi murk, drill, ambient drone',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-7',
  ),
  GenreTemplate(
    id: 'punk',
    label: 'Punk',
    styleSeed:
        'punk rock, raw urgent vocal, fast power chords, galloping drums, '
        'live garage energy, short and sharp, 180 BPM',
    excludeSeed: 'smooth R&B, orchestral ballad, chillhop',
    structureHint:
        '[Intro] [Verse 1] [Chorus] [Verse 2] [Chorus] [Bridge] [Chorus] [Outro]',
    verseSyllables: '5-9',
    chorusSyllables: '3-7',
  ),
  GenreTemplate(
    id: 'rnb',
    label: 'R&B / Soul',
    styleSeed:
        'contemporary R&B, smooth sensual midtempo, velvet lead vocal with melisma and soft ad-libs, '
        'warm Rhodes, deep sub bass, sparse trap-influenced drums, atmospheric pads, '
        'intimate late-night production, 92 BPM',
    excludeSeed: 'punk, metal, country twang, EDM drops',
    structureHint: _v1pc,
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
    structureHint:
        '[Intro] [Verse 1] [Chorus] [Verse 2] [Chorus] [Bridge] [Verse 3] [Chorus] [Outro]',
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
    id: 'shoegaze',
    label: 'Shoegaze',
    styleSeed:
        'shoegaze, washed walls of guitar, dreamy buried-or-floating vocal, '
        'reverb haze, soft-loud dynamics, immersive blur, 100 BPM',
    excludeSeed: 'dry acoustic country, trap punch, comedy novelty',
    structureHint: _v1c,
    verseSyllables: '5-9',
    chorusSyllables: '4-7',
  ),
  GenreTemplate(
    id: 'singer_songwriter',
    label: 'Singer-Songwriter',
    styleSeed:
        'singer-songwriter, piano or acoustic guitar first, intimate conversational vocal, '
        'sparse arrangement that grows gently, close-mic honesty, 84 BPM',
    excludeSeed: 'EDM drops, metal, trap flex',
    structureHint: _v1c,
    verseSyllables: '6-10',
    chorusSyllables: '5-8',
  ),
  GenreTemplate(
    id: 'ska',
    label: 'Ska / Two-Tone',
    styleSeed:
        'ska two-tone, upstroke guitar bounce, energetic vocal, horn section hits, '
        'walking bass, bright drums, danceable bounce, 150 BPM',
    excludeSeed: 'doom metal, ambient drone, whispered folk',
    structureHint: _v1c,
    verseSyllables: '6-11',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'soft_rock',
    label: 'Soft Rock',
    styleSeed:
        'soft rock, warm radio melodies, smooth lead vocal, clean guitars, '
        'gentle drums, 70s–80s sheen with modern clarity, 98 BPM',
    excludeSeed: 'harsh metal, drill, hyperpop chaos',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'southern_soul',
    label: 'Southern Soul',
    styleSeed:
        'southern soul, slow-burning deep soul ballad, raw fragile-to-powerful vocal, '
        'Rhodes and B3 organ, sparse brushed drums, Muscle Shoals warmth, 64–80 BPM',
    excludeSeed: 'EDM, trap, punk, icy synth-pop',
    structureHint: _v1pc,
    verseSyllables: '6-10',
    chorusSyllables: '4-8',
  ),
  GenreTemplate(
    id: 'techno',
    label: 'Techno',
    styleSeed:
        'techno, hypnotic machine pulse, sparse vocal hooks or spoken phrases, '
        'driving kick, evolving synth motifs, warehouse tension, 130 BPM',
    excludeSeed: 'acoustic ballad, country, broadway',
    structureHint:
        '[Intro] [Build] [Drop] [Break] [Drop] [Bridge] [Drop] [Outro]',
    verseSyllables: '4-8',
    chorusSyllables: '3-6',
  ),
  GenreTemplate(
    id: 'trap',
    label: 'Trap',
    styleSeed:
        'trap, hard 808s and rolling hats, melodic or aggressive vocal, '
        'dark atmospheric pads, punchy modern mix, 140 BPM',
    excludeSeed: 'acoustic folk, orchestral classical, bluegrass',
    structureHint:
        '[Intro] [Verse 1] [Chorus] [Verse 2] [Chorus] [Bridge] [Chorus] [Outro]',
    verseSyllables: '8-14',
    chorusSyllables: '4-9',
  ),
  GenreTemplate(
    id: 'trip_hop',
    label: 'Trip-Hop',
    styleSeed:
        'trip-hop, dusty downtempo groove, smoky intimate vocal, '
        'sampled textures, deep bass, cinematic noir mood, 85 BPM',
    excludeSeed: 'bright teen pop, country twang, power metal',
    structureHint: _v1c,
    verseSyllables: '5-10',
    chorusSyllables: '4-7',
  ),
];

GenreTemplate? genreById(String id) {
  for (final g in kGenreTemplates) {
    if (g.id == id) return g;
  }
  return null;
}

/// Favorites first (A–Z), then the rest (A–Z).
List<GenreTemplate> genresOrdered({required Set<String> favoriteIds}) {
  final favs = kGenreTemplates.where((g) => favoriteIds.contains(g.id)).toList()
    ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  final rest =
      kGenreTemplates.where((g) => !favoriteIds.contains(g.id)).toList()
        ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return [...favs, ...rest];
}

const List<String> kMoodOptions = [
  'Aching',
  'Angry',
  'Anxious',
  'Bittersweet',
  'Bold',
  'Brooding',
  'Celebratory',
  'Confident',
  'Dark',
  'Defiant',
  'Detached',
  'Dreamy',
  'Euphoric',
  'Fragile',
  'Grateful',
  'Gritty',
  'Hopeful',
  'Hungry',
  'Intimate',
  'Ironic',
  'Lonely',
  'Melancholy',
  'Mischievous',
  'Nostalgic',
  'Playful',
  'Proud',
  'Quiet',
  'Reckless',
  'Reflective',
  'Romantic',
  'Sarcastic',
  'Sensual',
  'Somber',
  'Tender',
  'Tense',
  'Triumphant',
  'Urgent',
  'Vulnerable',
  'Wry',
  'Yearning',
];

List<String> moodsOrdered({required Set<String> favoriteMoods}) {
  final favs = kMoodOptions.where(favoriteMoods.contains).toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  final rest = kMoodOptions.where((m) => !favoriteMoods.contains(m)).toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return [...favs, ...rest];
}
