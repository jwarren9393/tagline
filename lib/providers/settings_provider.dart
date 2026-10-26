import 'package:flutter/foundation.dart';

import '../models/nanogpt_catalog.dart';
import '../services/nanogpt_catalog_service.dart';
import '../services/secure_settings.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._settings) {
    _catalog = NanoGptCatalogService(settings: _settings);
  }

  final SecureSettings _settings;
  late final NanoGptCatalogService _catalog;

  bool loaded = false;
  bool hasApiKey = false;
  String model = SecureSettings.defaultModel;
  bool useSubscription = true;
  List<FavoriteModel> favorites = [];
  List<String> favoriteGenreIds = [];
  List<String> favoriteMoods = [];

  List<NanoGptModelInfo> catalog = [];
  bool catalogLoading = false;
  String? catalogError;

  String categoryFilter = NanoGptCatalogFilters.allCategoryId;
  String contextFilter = NanoGptCatalogFilters.contextAllId;
  String providerFilter = NanoGptCatalogFilters.allProviderId;

  NanoGptModelRuntimeStats? selectedRuntime;

  SecureSettings get settings => _settings;
  NanoGptCatalogService get catalogService => _catalog;

  String get baseUrl => useSubscription
      ? SecureSettings.subscriptionBaseUrl
      : SecureSettings.defaultBaseUrl;

  NanoGptModelInfo? get selectedModelInfo {
    for (final m in catalog) {
      if (m.id == model) return m;
    }
    return null;
  }

  List<NanoGptModelInfo> get filteredCatalog =>
      NanoGptCatalogFilters.applyPipeline(
        models: catalog,
        categoryId: categoryFilter,
        contextId: contextFilter,
        providerId: providerFilter,
      );

  int get filteredProviderCount {
    final set = <String>{};
    for (final m in filteredCatalog) {
      set.add(m.ownedBy);
    }
    return set.length;
  }

  bool isFavorite(String id) => favorites.any((f) => f.id == id);

  bool isFavoriteGenre(String id) => favoriteGenreIds.contains(id);

  bool isFavoriteMood(String mood) => favoriteMoods.contains(mood);

  Future<void> load() async {
    final key = await _settings.getApiKey();
    hasApiKey = key != null && key.isNotEmpty;
    model = await _settings.getModel();
    useSubscription = await _settings.getUseSubscription();
    favorites = await _settings.getFavorites();
    favoriteGenreIds = await _settings.getFavoriteGenreIds();
    favoriteMoods = await _settings.getFavoriteMoods();
    loaded = true;
    notifyListeners();
    if (hasApiKey) {
      // Fire-and-forget catalog warm
      refreshCatalog();
    }
  }

  Future<void> toggleFavoriteGenre(String id) async {
    favoriteGenreIds = await _settings.toggleFavoriteGenreId(id);
    notifyListeners();
  }

  Future<void> toggleFavoriteMood(String mood) async {
    favoriteMoods = await _settings.toggleFavoriteMood(mood);
    notifyListeners();
  }

  Future<void> saveApiKey(String key) async {
    await _settings.setApiKey(key);
    hasApiKey = key.trim().isNotEmpty;
    notifyListeners();
    if (hasApiKey) {
      await refreshCatalog();
    } else {
      catalog = [];
      catalogError = null;
      notifyListeners();
    }
  }

  Future<void> clearApiKey() async {
    await _settings.setApiKey(null);
    hasApiKey = false;
    catalog = [];
    catalogError = null;
    selectedRuntime = null;
    notifyListeners();
  }

  Future<void> saveModel(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    await _settings.setModel(trimmed);
    model = trimmed;
    notifyListeners();
    await _loadSelectedRuntime();
  }

  Future<void> saveModelAndConnection({
    required String modelId,
    required bool subscription,
  }) async {
    await _settings.setModel(modelId.trim());
    model = modelId.trim();
    final changed = useSubscription != subscription;
    await _settings.setUseSubscription(subscription);
    useSubscription = subscription;
    notifyListeners();
    if (changed) {
      await refreshCatalog();
    } else {
      await _loadSelectedRuntime();
    }
  }

  Future<void> saveUseSubscription(bool value) async {
    await _settings.setUseSubscription(value);
    useSubscription = value;
    notifyListeners();
    await refreshCatalog();
  }

  void setCategoryFilter(String id) {
    categoryFilter = id;
    // Reset provider when category changes so options stay valid
    providerFilter = NanoGptCatalogFilters.allProviderId;
    notifyListeners();
  }

  void setContextFilter(String id) {
    contextFilter = id;
    notifyListeners();
  }

  void setProviderFilter(String id) {
    providerFilter = id;
    notifyListeners();
  }

  Future<void> refreshCatalog() async {
    catalogLoading = true;
    catalogError = null;
    notifyListeners();
    try {
      catalog = await _catalog.listModels(baseUrl: baseUrl);
      // Keep filters coherent
      final cats = NanoGptCatalogFilters.categoryFilterIds(catalog);
      if (!cats.contains(categoryFilter)) {
        categoryFilter = NanoGptCatalogFilters.allCategoryId;
      }
      final providers =
          NanoGptCatalogFilters.providerFilterIds(filteredCatalog);
      if (!providers.contains(providerFilter)) {
        providerFilter = NanoGptCatalogFilters.allProviderId;
      }
      await _loadSelectedRuntime();
      // Warm a few browse-relevant stats
      final warm = filteredCatalog.take(12).map((m) => m.id);
      _catalog.prefetchRuntimeStats(warm);
    } catch (e) {
      catalogError = e.toString().replaceFirst('NanoGptException: ', '');
      catalog = [];
    } finally {
      catalogLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSelectedRuntime() async {
    if (model.isEmpty) {
      selectedRuntime = null;
      return;
    }
    selectedRuntime = await _catalog.fetchRuntimeStats(model);
    notifyListeners();
  }

  Future<void> toggleFavoriteFor(NanoGptModelInfo info) async {
    favorites = await _settings.toggleFavorite(
      FavoriteModel(
        id: info.id,
        label: info.displayName,
        provider: info.ownedBy,
      ),
    );
    notifyListeners();
  }

  Future<void> toggleFavoriteId(String id, {String label = '', String provider = ''}) async {
    favorites = await _settings.toggleFavorite(
      FavoriteModel(id: id, label: label, provider: provider),
    );
    notifyListeners();
  }

  Future<NanoGptCredits> loadCredits() => _catalog.getCredits();
}
