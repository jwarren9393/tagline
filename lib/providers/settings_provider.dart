import 'package:flutter/foundation.dart';

import '../services/secure_settings.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._settings);

  final SecureSettings _settings;

  bool loaded = false;
  bool hasApiKey = false;
  String model = SecureSettings.defaultModel;
  bool useSubscription = true;
  String? _apiKeyDraft;

  Future<void> load() async {
    final key = await _settings.getApiKey();
    hasApiKey = key != null && key.isNotEmpty;
    model = await _settings.getModel();
    useSubscription = await _settings.getUseSubscription();
    loaded = true;
    notifyListeners();
  }

  Future<void> saveApiKey(String key) async {
    await _settings.setApiKey(key);
    hasApiKey = key.trim().isNotEmpty;
    _apiKeyDraft = null;
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    await _settings.setApiKey(null);
    hasApiKey = false;
    notifyListeners();
  }

  Future<void> saveModel(String value) async {
    await _settings.setModel(value);
    model = value.trim();
    notifyListeners();
  }

  Future<void> saveUseSubscription(bool value) async {
    await _settings.setUseSubscription(value);
    useSubscription = value;
    notifyListeners();
  }

  String? get apiKeyDraft => _apiKeyDraft;
  set apiKeyDraft(String? v) {
    _apiKeyDraft = v;
    notifyListeners();
  }

  SecureSettings get settings => _settings;
}
