import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_paths.dart';

/// Persists API credentials and prefs under the portable userdata root.
///
/// - `api_key.txt` — NanoGPT key (travels with the install folder on Windows)
/// - `settings.json` — model, subscription flag, favorites, genres, moods
class SecureSettings {
  SecureSettings({Directory? overrideRoot}) : _overrideRoot = overrideRoot;

  final Directory? _overrideRoot;

  static const apiKeyStorageKey = 'nanogpt_api_key';
  static const modelKey = 'nanogpt_model';
  static const baseUrlKey = 'nanogpt_base_url';
  static const useSubscriptionKey = 'nanogpt_use_subscription';
  static const favoritesKey = 'nanogpt_favorite_models';
  static const favoriteGenresKey = 'tagline_favorite_genres';
  static const favoriteMoodsKey = 'tagline_favorite_moods';

  static const defaultModel = 'openai/gpt-4o';

  /// Pay-as-you-go OpenAI-compatible root (Anima parity).
  static const defaultBaseUrl = 'https://nano-gpt.com/api/v1';

  /// Subscription OpenAI-compatible root.
  static const subscriptionBaseUrl =
      'https://nano-gpt.com/api/subscription/v1';

  Future<Directory> _root() async {
    final override = _overrideRoot;
    if (override != null) {
      await override.create(recursive: true);
      return override;
    }
    return AppPaths.portableDocumentsDirectory();
  }

  Future<File> _apiKeyFile() async =>
      File(p.join((await _root()).path, AppPaths.apiKeyFileName));

  Future<File> _settingsFile() async =>
      File(p.join((await _root()).path, AppPaths.settingsFileName));

  Future<Map<String, dynamic>> _readSettings() async {
    final file = await _settingsFile();
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  Future<void> _writeSettings(Map<String, dynamic> map) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(map),
      flush: true,
    );
  }

  Future<String?> getApiKey() async {
    final file = await _apiKeyFile();
    if (!await file.exists()) return null;
    final value = (await file.readAsString()).trim();
    return value.isEmpty ? null : value;
  }

  Future<void> setApiKey(String? value) async {
    final file = await _apiKeyFile();
    if (value == null || value.trim().isEmpty) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.parent.create(recursive: true);
    await file.writeAsString(value.trim(), flush: true);
  }

  Future<String> getModel() async {
    final map = await _readSettings();
    final value = '${map[modelKey] ?? ''}'.trim();
    return value.isEmpty ? defaultModel : value;
  }

  Future<void> setModel(String model) async {
    final map = await _readSettings();
    map[modelKey] = model.trim();
    await _writeSettings(map);
  }

  Future<String> getBaseUrl() async {
    if (await getUseSubscription()) return subscriptionBaseUrl;
    final map = await _readSettings();
    final custom = '${map[baseUrlKey] ?? ''}'.trim();
    return custom.isEmpty ? defaultBaseUrl : custom;
  }

  Future<bool> getUseSubscription() async {
    final map = await _readSettings();
    if (!map.containsKey(useSubscriptionKey)) return true;
    return map[useSubscriptionKey] == true;
  }

  Future<void> setUseSubscription(bool value) async {
    final map = await _readSettings();
    map[useSubscriptionKey] = value;
    await _writeSettings(map);
  }

  Future<void> setCustomBaseUrl(String url) async {
    final map = await _readSettings();
    map[baseUrlKey] = url.trim();
    await _writeSettings(map);
  }

  /// Favorite model ids, newest first.
  Future<List<FavoriteModel>> getFavorites() async {
    final map = await _readSettings();
    final raw = map[favoritesKey];
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) return [];
        return decoded
            .whereType<Map>()
            .map((e) => FavoriteModel.fromJson(Map<String, dynamic>.from(e)))
            .where((f) => f.id.isNotEmpty)
            .toList();
      } catch (_) {
        return [];
      }
    }
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => FavoriteModel.fromJson(Map<String, dynamic>.from(e)))
          .where((f) => f.id.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<void> setFavorites(List<FavoriteModel> favorites) async {
    final map = await _readSettings();
    map[favoritesKey] = favorites.map((f) => f.toJson()).toList();
    await _writeSettings(map);
  }

  Future<List<FavoriteModel>> toggleFavorite(FavoriteModel entry) async {
    final current = await getFavorites();
    final exists = current.any((f) => f.id == entry.id);
    final next = exists
        ? current.where((f) => f.id != entry.id).toList()
        : [entry, ...current.where((f) => f.id != entry.id)];
    await setFavorites(next);
    return next;
  }

  Future<List<String>> getFavoriteGenreIds() async {
    final map = await _readSettings();
    final raw = map[favoriteGenresKey];
    if (raw is List) {
      return [for (final e in raw) '$e'];
    }
    return const [];
  }

  Future<void> setFavoriteGenreIds(List<String> ids) async {
    final map = await _readSettings();
    map[favoriteGenresKey] = ids;
    await _writeSettings(map);
  }

  Future<List<String>> toggleFavoriteGenreId(String id) async {
    final current = await getFavoriteGenreIds();
    final next = current.contains(id)
        ? current.where((e) => e != id).toList()
        : [...current, id];
    await setFavoriteGenreIds(next);
    return next;
  }

  Future<List<String>> getFavoriteMoods() async {
    final map = await _readSettings();
    final raw = map[favoriteMoodsKey];
    if (raw is List) {
      return [for (final e in raw) '$e'];
    }
    return const [];
  }

  Future<void> setFavoriteMoods(List<String> moods) async {
    final map = await _readSettings();
    map[favoriteMoodsKey] = moods;
    await _writeSettings(map);
  }

  Future<List<String>> toggleFavoriteMood(String mood) async {
    final current = await getFavoriteMoods();
    final next = current.contains(mood)
        ? current.where((e) => e != mood).toList()
        : [...current, mood];
    await setFavoriteMoods(next);
    return next;
  }
}

class FavoriteModel {
  const FavoriteModel({
    required this.id,
    this.label = '',
    this.provider = '',
  });

  final String id;
  final String label;
  final String provider;

  String get display => label.trim().isEmpty ? id : label.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'provider': provider,
      };

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: '${json['id'] ?? ''}'.trim(),
      label: '${json['label'] ?? ''}'.trim(),
      provider: '${json['provider'] ?? ''}'.trim(),
    );
  }
}
