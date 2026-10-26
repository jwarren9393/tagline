import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists API credentials securely and non-secret prefs plainly.
class SecureSettings {
  SecureSettings({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _apiKeyKey = 'nanogpt_api_key';
  static const _modelKey = 'nanogpt_model';
  static const _baseUrlKey = 'nanogpt_base_url';
  static const _useSubscriptionKey = 'nanogpt_use_subscription';
  static const _favoritesKey = 'nanogpt_favorite_models';
  static const _favoriteGenresKey = 'tagline_favorite_genres';
  static const _favoriteMoodsKey = 'tagline_favorite_moods';

  static const defaultModel = 'openai/gpt-4o';

  /// Pay-as-you-go OpenAI-compatible root (Anima parity).
  static const defaultBaseUrl = 'https://nano-gpt.com/api/v1';

  /// Subscription OpenAI-compatible root.
  static const subscriptionBaseUrl =
      'https://nano-gpt.com/api/subscription/v1';

  Future<String?> getApiKey() => _storage.read(key: _apiKeyKey);

  Future<void> setApiKey(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _storage.delete(key: _apiKeyKey);
    } else {
      await _storage.write(key: _apiKeyKey, value: value.trim());
    }
  }

  Future<String> getModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelKey) ?? defaultModel;
  }

  Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model.trim());
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final useSub = prefs.getBool(_useSubscriptionKey) ?? true;
    if (useSub) return subscriptionBaseUrl;
    return prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
  }

  Future<bool> getUseSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useSubscriptionKey) ?? true;
  }

  Future<void> setUseSubscription(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useSubscriptionKey, value);
  }

  Future<void> setCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url.trim());
  }

  /// Favorite model ids, newest first.
  Future<List<FavoriteModel>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) return [];
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

  Future<void> setFavorites(List<FavoriteModel> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _favoritesKey,
      jsonEncode(favorites.map((f) => f.toJson()).toList()),
    );
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoriteGenresKey) ?? const [];
  }

  Future<void> setFavoriteGenreIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteGenresKey, ids);
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoriteMoodsKey) ?? const [];
  }

  Future<void> setFavoriteMoods(List<String> moods) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteMoodsKey, moods);
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
