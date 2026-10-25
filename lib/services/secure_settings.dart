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

  static const defaultModel = 'openai/gpt-4o';
  static const defaultBaseUrl = 'https://api.nano-gpt.com/api/v1';
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
}
