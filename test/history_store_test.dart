import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tagline/models/generation_result.dart';
import 'package:tagline/models/generation_session.dart';
import 'package:tagline/models/song_idea.dart';
import 'package:tagline/services/history_store.dart';

void main() {
  late Directory tempDir;
  late HistoryStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tagline_history_');
    store = HistoryStore(overrideDir: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('upsert and load sessions', () async {
    final now = DateTime.utc(2026, 10, 24, 12);
    final session = GenerationSession(
      id: 'abc',
      createdAt: now,
      updatedAt: now,
      idea: const SongIdea(rawIdea: 'Cold coffee at dawn in a quiet kitchen.'),
      result: const GenerationResult(
        lyrics: '[Verse 1]\nCold coffee on the counter\n\n[Chorus]\nStay, oh',
        stylePrompt: 'indie folk, intimate, 88 BPM',
        title: 'Cold Coffee',
      ),
    );

    await store.upsert(session);
    final loaded = await store.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.first.titleOrIdea, 'Cold Coffee');
    expect(loaded.first.result.lyrics, contains('Cold coffee'));
  });

  test('delete removes session', () async {
    final now = DateTime.now().toUtc();
    await store.upsert(
      GenerationSession(
        id: 'one',
        createdAt: now,
        updatedAt: now,
        idea: const SongIdea(rawIdea: 'Idea one that is long enough.'),
        result: const GenerationResult(lyrics: 'a', stylePrompt: 'pop, 120 BPM'),
      ),
    );
    await store.upsert(
      GenerationSession(
        id: 'two',
        createdAt: now,
        updatedAt: now,
        idea: const SongIdea(rawIdea: 'Idea two that is long enough.'),
        result: const GenerationResult(lyrics: 'b', stylePrompt: 'rock, 128 BPM'),
      ),
    );
    final after = await store.delete('one');
    expect(after.map((s) => s.id), ['two']);
  });
}

extension on GenerationSession {
  String get titleOrIdea => displayTitle;
}
