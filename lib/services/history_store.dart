import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/generation_session.dart';

/// JSON file store for generation sessions under the app documents directory.
class HistoryStore {
  HistoryStore({this.overrideDir});

  final Directory? overrideDir;
  static const _fileName = 'tagline_history.json';
  static const maxSessions = 200;

  Future<File> _file() async {
    final dir = overrideDir ?? await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<List<GenerationSession>> loadAll() async {
    final file = await _file();
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final sessions = decoded
          .whereType<Map>()
          .map((e) => GenerationSession.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      sessions.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return sessions;
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeAll(List<GenerationSession> sessions) async {
    var list = List<GenerationSession>.from(sessions);
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    if (list.length > maxSessions) {
      // Prefer dropping unpinned oldest
      final pinned = list.where((s) => s.pinned).toList();
      final unpinned = list.where((s) => !s.pinned).toList();
      while (pinned.length + unpinned.length > maxSessions &&
          unpinned.isNotEmpty) {
        unpinned.removeLast();
      }
      list = [...pinned, ...unpinned];
    }
    final file = await _file();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        list.map((s) => s.toJson()).toList(),
      ),
    );
  }

  Future<List<GenerationSession>> upsert(GenerationSession session) async {
    final all = await loadAll();
    final idx = all.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      all[idx] = session;
    } else {
      all.insert(0, session);
    }
    await _writeAll(all);
    return loadAll();
  }

  /// Upsert many sessions (e.g. device-to-device import). Same ids replace.
  Future<List<GenerationSession>> upsertAll(
    Iterable<GenerationSession> sessions,
  ) async {
    final all = await loadAll();
    for (final session in sessions) {
      final idx = all.indexWhere((s) => s.id == session.id);
      if (idx >= 0) {
        all[idx] = session;
      } else {
        all.insert(0, session);
      }
    }
    await _writeAll(all);
    return loadAll();
  }

  Future<List<GenerationSession>> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((s) => s.id == id);
    await _writeAll(all);
    return loadAll();
  }

  Future<List<GenerationSession>> clear() async {
    await _writeAll([]);
    return [];
  }
}
