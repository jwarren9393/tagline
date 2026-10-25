import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tagline/models/generation_result.dart';
import 'package:tagline/models/generation_session.dart';
import 'package:tagline/models/song_idea.dart';
import 'package:tagline/services/export_service.dart';

void main() {
  const export = ExportService();

  GenerationSession sample({String id = 'abc-123'}) {
    final now = DateTime.utc(2026, 10, 25, 12);
    return GenerationSession(
      id: id,
      createdAt: now,
      updatedAt: now,
      idea: const SongIdea(
        rawIdea: 'Cold coffee and a quiet kitchen at dawn.',
        genreId: 'indie_folk',
        moods: ['Bittersweet'],
      ),
      result: const GenerationResult(
        lyrics: '[Verse 1]\nCold coffee on the counter\n\n[Chorus]\nStay, oh',
        stylePrompt: 'indie folk, intimate, 88 BPM',
        title: 'Cold Coffee',
      ),
      tags: const ['demo'],
      sunoFeedback: 'Chorus landed',
    );
  }

  test('round-trips a single session envelope', () {
    final session = sample();
    final raw = export.encodeSessionFile(session);
    final imported = export.parseImport(raw);
    expect(imported, hasLength(1));
    expect(imported.first.id, session.id);
    expect(imported.first.result.title, 'Cold Coffee');
    expect(imported.first.idea.rawIdea, contains('Cold coffee'));
    expect(imported.first.tags, ['demo']);
    expect(imported.first.sunoFeedback, 'Chorus landed');
  });

  test('round-trips a history backup', () {
    final raw = export.encodeHistoryFile([sample(id: 'a'), sample(id: 'b')]);
    final imported = export.parseImport(raw);
    expect(imported.map((s) => s.id).toList(), ['a', 'b']);
  });

  test('accepts bare session JSON without envelope', () {
    final session = sample();
    final bare = export.parseImport(jsonEncode(session.toJson()));
    expect(bare, hasLength(1));
    expect(bare.first.id, session.id);
  });

  test('rejects unknown files', () {
    expect(
      () => export.parseImport('{"hello":true}'),
      throwsA(isA<ExportException>()),
    );
  });
}
