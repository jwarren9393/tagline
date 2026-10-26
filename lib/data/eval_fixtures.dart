/// Good vs bad lyric/style fixtures for the prompt eval harness.
/// Not copyrighted songs — synthetic examples for regression tests.
library;

/// Voice + rhyme + even meter: a song, not free-verse talk or prop pastiche.
const kGoodLyricsFixture = '''
[Intro]

[Verse 1]
You left your jacket on my chair
I almost hung it up right there
Then I pictured that cold drive home
And left it for you on its own

[Pre-Chorus]
Don't make this into something large
I'm not here to ask or charge

[Chorus]
Don't say it out loud yet
Don't say it out loud yet
Leave the light the way it is
Don't say it out loud yet

[Verse 2]
I typed "you home?" about three times
Deleted twice, then crossed the line
You hearted it and that was all
Guess that's just us after the fall

[Chorus]
Don't say it out loud yet
Don't say it out loud yet
Leave the light the way it is
Don't say it out loud yet

[Bridge]
If you walk in now I'll act surprised
Like I wasn't waiting with these tired eyes

[Chorus]
Don't say it out loud yet
Don't say it out loud yet
Leave the light the way it is
Don't say it out loud yet

[Outro]
''';

const kGoodStyleFixture =
    'indie folk, intimate bittersweet midtempo, close-mic conversational vocal, '
    'fingerpicked acoustic guitar, soft brushes, upright bass, warm room production, 88 BPM';

const kGoodExcludeFixture = 'EDM, autotune, trap drums, stadium rock';

const kBadLyricsFixture = '''
[Verse 1]
My heart is broken in the neon lights forever
I'm fading into the shadows of the city lights tonight and I feel so empty inside my soul
I will rise above and chase my dreams until eternity calls my name somehow

[Chorus]
I will always love you through every single storm that we weather together forevermore under the stars
I will always love you differently somehow with passion burning like a fire in my soul forever

[Verse 2]
Drowning in tears like rain at midnight hour with whispers of secrets written in the stars
Cold linoleum, bare feet at one a.m. with a trembling hand in the mirror fog
Cold tile soaks right through my socks by the bathroom fan
''';

const kBadStyleFixture =
    'A song about heartbreak with no drums, without guitars, avoid rock. '
    'Verse and chorus tell the story of lost love. [Chorus] emotional.';
