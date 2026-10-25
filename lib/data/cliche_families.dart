/// Constrained list of overused lyric cliché families.
/// These should be avoided or heavily "earned" with surrounding concrete detail.
library;

const List<ClicheFamily> kClicheFamilies = [
  ClicheFamily(
    id: 'neon_lights',
    label: 'Neon / city glow',
    terms: [
      'neon lights',
      'neon signs',
      'city lights',
      'streetlights',
      'glowing streets',
    ],
  ),
  ClicheFamily(
    id: 'broken_heart',
    label: 'Broken heart',
    terms: [
      'broken heart',
      'heart breaks',
      'heartbreak',
      'shattered heart',
      'piece of my heart',
    ],
  ),
  ClicheFamily(
    id: 'forever',
    label: 'Forever / eternity',
    terms: [
      'forever',
      'eternity',
      'til the end of time',
      'until the end of time',
      'always and forever',
    ],
  ),
  ClicheFamily(
    id: 'fading',
    label: 'Fading / slipping away',
    terms: [
      'fading away',
      'slipping away',
      'drifting away',
      'fading light',
      'losing myself',
    ],
  ),
  ClicheFamily(
    id: 'shadows',
    label: 'Shadows / darkness',
    terms: [
      'in the shadows',
      'dancing with shadows',
      'shadows of',
      'darkness calls',
      'into the dark',
    ],
  ),
  ClicheFamily(
    id: 'rising_above',
    label: 'Rising above / overcoming',
    terms: [
      'rising above',
      'rise above',
      'overcome',
      'break free',
      'spread my wings',
      'find my way',
      'stronger than before',
    ],
  ),
  ClicheFamily(
    id: 'fire_burn',
    label: 'Fire / burning passion',
    terms: [
      'set on fire',
      'burning desire',
      'flames of',
      'fire in my',
      'burn for you',
      'ignite',
    ],
  ),
  ClicheFamily(
    id: 'rain_tears',
    label: 'Rain / tears',
    terms: [
      'tears like rain',
      'crying in the rain',
      'rain on my',
      'washed away',
      'drowning in',
    ],
  ),
  ClicheFamily(
    id: 'stars_destiny',
    label: 'Stars / destiny',
    terms: [
      'written in the stars',
      'reach for the stars',
      'star-crossed',
      'destiny calls',
      'meant to be',
      'fate brought us',
    ],
  ),
  ClicheFamily(
    id: 'empty_feelings',
    label: 'Abstract emptiness',
    terms: [
      'feel empty',
      'feeling empty',
      'hollow inside',
      'void inside',
      'numb',
      'lost without you',
      'nothing without you',
    ],
  ),
  ClicheFamily(
    id: 'dreams_chase',
    label: 'Chasing dreams',
    terms: [
      'chase my dreams',
      'chasing dreams',
      'follow my dreams',
      'dreams come true',
      'living the dream',
    ],
  ),
  ClicheFamily(
    id: 'midnight',
    label: 'Generic midnight',
    terms: [
      'midnight hour',
      'at midnight',
      'past midnight',
      'dead of night',
    ],
  ),
  ClicheFamily(
    id: 'whisper_secrets',
    label: 'Whispers / secrets',
    terms: [
      'whisper secrets',
      'secrets in the',
      'whispers in the dark',
      'untold secrets',
    ],
  ),
  ClicheFamily(
    id: 'soulmate',
    label: 'Soul / soulmate',
    terms: [
      'soulmate',
      'two souls',
      'soul to soul',
      'touch my soul',
      'deep in my soul',
    ],
  ),
];

class ClicheFamily {
  const ClicheFamily({
    required this.id,
    required this.label,
    required this.terms,
  });

  final String id;
  final String label;
  final List<String> terms;
}

/// Flat list of terms for prompt injection and local scanning.
List<String> get allClicheTerms =>
    kClicheFamilies.expand((f) => f.terms).toList(growable: false);
