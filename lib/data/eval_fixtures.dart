/// Good vs bad lyric/style fixtures for the prompt eval harness.
/// Not copyrighted songs — synthetic examples for regression tests.
library;

const kGoodLyricsFixture = '''
[Intro]

[Verse 1]
Your mug's still in the sink from Thursday
Lipstick print dried on the rim
I leave the porch light on way too late
Like you might still pull in

[Pre-Chorus]
Truck coughs once in the driveway cold
I laugh like that means I'm fine

[Chorus]
Stay a little longer, oh
Stay a little longer, oh
Keys on the table, coat on the chair
Stay a little longer, oh

[Verse 2]
Half a grocery list stuck to the fridge
Milk and oranges, your handwriting
The kettle clicks and I don't pour it
Just stand there listening

[Chorus]
Stay a little longer, oh
Stay a little longer, oh
Keys on the table, coat on the chair
Stay a little longer, oh

[Bridge]
I fold your laundry wrong on purpose
So you'll complain when you get home

[Chorus]
Stay a little longer, oh
Stay a little longer, oh
Keys on the table, coat on the chair
Stay a little longer, oh

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
''';

const kBadStyleFixture =
    'A song about heartbreak with no drums, without guitars, avoid rock. '
    'Verse and chorus tell the story of lost love. [Chorus] emotional.';
