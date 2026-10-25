import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/generation_result.dart';
import '../models/song_idea.dart';

/// Clipboard-friendly packs and share-sheet export for Suno paste.
class ExportService {
  const ExportService();

  String buildPack({
    required SongIdea idea,
    required GenerationResult result,
  }) {
    final buf = StringBuffer();
    if (result.title.trim().isNotEmpty) {
      buf.writeln('TITLE: ${result.title.trim()}');
      buf.writeln();
    }
    buf.writeln('=== STYLE (Suno Style field) ===');
    buf.writeln(result.stylePrompt.trim());
    buf.writeln();
    buf.writeln('=== EXCLUDE STYLES ===');
    buf.writeln(
      result.excludeStyles.trim().isEmpty
          ? '(none)'
          : result.excludeStyles.trim(),
    );
    buf.writeln();
    buf.writeln('=== LYRICS (Suno Lyrics field) ===');
    buf.writeln(result.lyrics.trim());
    buf.writeln();
    buf.writeln('=== ORIGINAL TAGLINE PROMPT ===');
    buf.writeln(idea.rawIdea.trim());
    if (idea.titleHint.trim().isNotEmpty) {
      buf.writeln('\nTitle hint: ${idea.titleHint.trim()}');
    }
    if (idea.referenceVibes.trim().isNotEmpty) {
      buf.writeln('Vibes: ${idea.referenceVibes.trim()}');
    }
    if (idea.constraints.trim().isNotEmpty) {
      buf.writeln('Constraints: ${idea.constraints.trim()}');
    }
    if (idea.genre != null) {
      buf.writeln('Genre: ${idea.genre!.label}');
    }
    if (idea.moods.isNotEmpty) {
      buf.writeln('Moods: ${idea.moods.join(', ')}');
    }
    return buf.toString().trim();
  }

  Future<void> sharePack({
    required SongIdea idea,
    required GenerationResult result,
  }) async {
    final text = buildPack(idea: idea, result: result);
    final dir = await getTemporaryDirectory();
    final safeName = (result.title.trim().isEmpty ? 'tagline' : result.title)
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final file = File(p.join(dir.path, '${safeName}_suno.txt'));
    await file.writeAsString(text);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: text,
        subject: result.title.trim().isEmpty
            ? 'Tagline → Suno pack'
            : 'Tagline: ${result.title.trim()}',
      ),
    );
  }
}
