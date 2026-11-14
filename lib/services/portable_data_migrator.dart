import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_paths.dart';
import 'secure_settings.dart';

/// One-time copy of legacy scatter paths into [AppPaths.root].
///
/// Migrates Tagline-owned history / settings / API key only. Does **not**
/// touch the user's personal Libraries or Documents trees beyond reading the
/// old flat `tagline_history.json` that lived directly under documents.
class PortableDataMigrator {
  PortableDataMigrator._();

  static const markerName = '.migrated_portable_v1';

  /// Runs migration if the portable marker is missing. Safe to call every launch.
  static Future<void> migrateIfNeeded(
    AppPaths paths, {
    Future<Directory> Function()? documentsDirectory,
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences> Function()? sharedPreferences,
  }) async {
    final marker = File(p.join(paths.root.path, markerName));
    if (await marker.exists()) {
      return;
    }

    final notes = <String>[];
    final getDocuments =
        documentsDirectory ?? getApplicationDocumentsDirectory;
    final storage = secureStorage ?? const FlutterSecureStorage();
    final getPrefs = sharedPreferences ?? SharedPreferences.getInstance;

    try {
      final documents = await getDocuments();
      final legacyHistory = File(
        p.join(documents.path, AppPaths.historyFileName),
      );
      if (await legacyHistory.exists() && !await paths.historyFile.exists()) {
        await legacyHistory.copy(paths.historyFile.path);
        notes.add('history');
      }
    } catch (e) {
      notes.add('documents migrate error: $e');
    }

    try {
      if (!await paths.settingsFile.exists()) {
        final prefs = await getPrefs();
        final map = <String, dynamic>{};
        final model = prefs.getString(SecureSettings.modelKey);
        if (model != null && model.trim().isNotEmpty) {
          map[SecureSettings.modelKey] = model.trim();
        }
        final baseUrl = prefs.getString(SecureSettings.baseUrlKey);
        if (baseUrl != null && baseUrl.trim().isNotEmpty) {
          map[SecureSettings.baseUrlKey] = baseUrl.trim();
        }
        if (prefs.containsKey(SecureSettings.useSubscriptionKey)) {
          map[SecureSettings.useSubscriptionKey] =
              prefs.getBool(SecureSettings.useSubscriptionKey);
        }
        final favorites = prefs.getString(SecureSettings.favoritesKey);
        if (favorites != null && favorites.isNotEmpty) {
          map[SecureSettings.favoritesKey] = favorites;
        }
        final genres = prefs.getStringList(SecureSettings.favoriteGenresKey);
        if (genres != null && genres.isNotEmpty) {
          map[SecureSettings.favoriteGenresKey] = genres;
        }
        final moods = prefs.getStringList(SecureSettings.favoriteMoodsKey);
        if (moods != null && moods.isNotEmpty) {
          map[SecureSettings.favoriteMoodsKey] = moods;
        }
        if (map.isNotEmpty) {
          await paths.settingsFile.writeAsString(
            const JsonEncoder.withIndent('  ').convert(map),
            flush: true,
          );
          notes.add('settings (${map.length} keys)');
        }
      }
    } catch (e) {
      notes.add('prefs migrate error: $e');
    }

    try {
      if (!await paths.apiKeyFile.exists()) {
        final key = await storage.read(key: SecureSettings.apiKeyStorageKey);
        if (key != null && key.trim().isNotEmpty) {
          await paths.apiKeyFile.writeAsString(key.trim(), flush: true);
          notes.add('api_key');
        }
      }
    } catch (e) {
      notes.add('api key migrate error: $e');
    }

    await marker.writeAsString(
      'migrated=${DateTime.now().toUtc().toIso8601String()}\n'
      'notes=${notes.join('; ')}\n',
      flush: true,
    );
  }
}
