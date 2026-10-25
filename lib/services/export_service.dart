import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/generation_result.dart';
import '../models/generation_session.dart';
import '../models/song_idea.dart';

/// Clipboard packs, share sheets, and portable session import/export.
class ExportService {
  const ExportService();

  static const sessionFormat = 'tagline.session';
  static const sessionVersion = 1;
  static const historyFormat = 'tagline.history';
  static const historyVersion = 1;

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

  /// Share Suno pack. File-only on mobile (no simultaneous `text` + `files`,
  /// which freezes share_plus on many Android builds). Desktop uses Save.
  Future<ShareOutcome> sharePack({
    required SongIdea idea,
    required GenerationResult result,
    Rect? sharePositionOrigin,
  }) async {
    final text = buildPack(idea: idea, result: result);
    final fileName =
        '${_safeFileBase(result.title, fallback: 'tagline')}_suno.txt';
    final bytes = Uint8List.fromList(utf8.encode(text));

    if (_preferSaveDialog) {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save Suno pack',
        fileName: fileName,
        bytes: bytes,
        mimeType: 'text/plain',
      );
      if (uri == null) return ShareOutcome.cancelled;
      return ShareOutcome.saved(uri.toString());
    }

    final file = await _writeTempFile(fileName: fileName, contents: text);
    try {
      final shareResult = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/plain')],
          subject: result.title.trim().isEmpty
              ? 'Tagline → Suno pack'
              : 'Tagline: ${result.title.trim()}',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      if (shareResult.status == ShareResultStatus.dismissed) {
        return ShareOutcome.cancelled;
      }
      return ShareOutcome.shared;
    } catch (e) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: 'Tagline → Suno pack',
            sharePositionOrigin: sharePositionOrigin,
          ),
        );
        return ShareOutcome.shared;
      } catch (_) {
        throw ExportException('Could not open the share sheet: $e');
      }
    }
  }

  Map<String, dynamic> sessionEnvelope(GenerationSession session) => {
        'format': sessionFormat,
        'version': sessionVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'session': session.toJson(),
      };

  Map<String, dynamic> historyEnvelope(List<GenerationSession> sessions) => {
        'format': historyFormat,
        'version': historyVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };

  String encodeSessionFile(GenerationSession session) =>
      const JsonEncoder.withIndent('  ').convert(sessionEnvelope(session));

  String encodeHistoryFile(List<GenerationSession> sessions) =>
      const JsonEncoder.withIndent('  ').convert(historyEnvelope(sessions));

  /// Parse a Tagline session or history backup file into sessions.
  List<GenerationSession> parseImport(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const ExportException('Not a Tagline export file.');
    }
    final map = Map<String, dynamic>.from(decoded);
    final format = '${map['format'] ?? ''}'.trim();

    if (format == sessionFormat || map.containsKey('session')) {
      final sessionRaw = map['session'];
      if (sessionRaw is! Map) {
        throw const ExportException('Session export is missing session data.');
      }
      return [
        GenerationSession.fromJson(Map<String, dynamic>.from(sessionRaw)),
      ];
    }

    if (format == historyFormat || map.containsKey('sessions')) {
      final list = map['sessions'];
      if (list is! List) {
        throw const ExportException('History export is missing sessions.');
      }
      return list
          .whereType<Map>()
          .map((e) => GenerationSession.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (map.containsKey('id') &&
        map.containsKey('idea') &&
        map.containsKey('result')) {
      return [GenerationSession.fromJson(map)];
    }

    throw const ExportException(
      'Unrecognized file. Export a session or history from Tagline first.',
    );
  }

  Future<ShareOutcome> exportSessionFile(
    GenerationSession session, {
    Rect? sharePositionOrigin,
  }) async {
    final json = encodeSessionFile(session);
    final base = _safeFileBase(session.displayTitle, fallback: 'session');
    final fileName = 'tagline_$base.tagline.json';
    final bytes = Uint8List.fromList(utf8.encode(json));

    if (_preferSaveDialog) {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Export Tagline session',
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/json',
      );
      if (uri == null) return ShareOutcome.cancelled;
      return ShareOutcome.saved(uri.toString());
    }

    final file = await _writeTempFile(fileName: fileName, contents: json);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Tagline session: ${session.displayTitle}',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      return ShareOutcome.shared;
    } catch (e) {
      throw ExportException('Could not export session: $e');
    }
  }

  Future<ShareOutcome> exportHistoryFile(
    List<GenerationSession> sessions, {
    Rect? sharePositionOrigin,
  }) async {
    final json = encodeHistoryFile(sessions);
    const fileName = 'tagline_history_backup.tagline.json';
    final bytes = Uint8List.fromList(utf8.encode(json));

    if (_preferSaveDialog) {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Export Tagline history',
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/json',
      );
      if (uri == null) return ShareOutcome.cancelled;
      return ShareOutcome.saved(uri.toString());
    }

    final file = await _writeTempFile(fileName: fileName, contents: json);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Tagline history (${sessions.length} sessions)',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      return ShareOutcome.shared;
    } catch (e) {
      throw ExportException('Could not export history: $e');
    }
  }

  /// Opens a file picker and returns parsed sessions (empty if cancelled).
  Future<List<GenerationSession>> pickAndParseImport() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Import Tagline session',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty) return const [];

    final file = files.single;
    final bytes = await file.readAsBytes();
    final raw = utf8.decode(bytes);
    return parseImport(raw);
  }

  bool get _preferSaveDialog =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  Future<File> _writeTempFile({
    required String fileName,
    required String contents,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(contents);
    return file;
  }

  String _safeFileBase(String title, {required String fallback}) {
    final cleaned = title
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    if (cleaned.isEmpty) return fallback;
    return cleaned.length > 48 ? cleaned.substring(0, 48) : cleaned;
  }
}

class ShareOutcome {
  const ShareOutcome._(this.kind, {this.path});

  final ShareOutcomeKind kind;
  final String? path;

  static const shared = ShareOutcome._(ShareOutcomeKind.shared);
  static const cancelled = ShareOutcome._(ShareOutcomeKind.cancelled);
  static ShareOutcome saved(String path) =>
      ShareOutcome._(ShareOutcomeKind.saved, path: path);

  bool get isCancelled => kind == ShareOutcomeKind.cancelled;
}

enum ShareOutcomeKind { shared, saved, cancelled }

class ExportException implements Exception {
  const ExportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Helper for share sheet positioning (tablets / desktop popovers).
Rect? shareOriginFromContext(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  final origin = box.localToGlobal(Offset.zero);
  return origin & box.size;
}
