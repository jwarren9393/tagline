import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/nanogpt_catalog.dart';
import 'nanogpt_client.dart';
import 'secure_settings.dart';

/// Catalog, credits, and runtime stats for NanoGPT (settings UX).
class NanoGptCatalogService {
  NanoGptCatalogService({
    required this.settings,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final SecureSettings settings;
  final http.Client _http;

  final Map<String, NanoGptModelRuntimeStats> _runtimeCache = {};

  NanoGptModelRuntimeStats cachedRuntimeStats(String modelId) =>
      _runtimeCache[modelId.trim()] ?? const NanoGptModelRuntimeStats();

  void clearRuntimeStatsCache() => _runtimeCache.clear();

  Future<Map<String, String>> _authHeaders({bool requireKey = true}) async {
    final apiKey = await settings.getApiKey();
    if (requireKey && (apiKey == null || apiKey.isEmpty)) {
      throw NanoGptException(
        'Add your NanoGPT API key in Settings first.',
      );
    }
    final headers = <String, String>{'Accept': 'application/json'};
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
      headers['x-api-key'] = apiKey;
    }
    return headers;
  }

  Future<List<NanoGptModelInfo>> listModels({String? baseUrl}) async {
    final root = (baseUrl ?? await settings.getBaseUrl())
        .trim()
        .replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$root/models')
        .replace(queryParameters: const {'detailed': 'true'});

    late final http.Response response;
    try {
      response = await _http
          .get(uri, headers: await _authHeaders(requireKey: false))
          .timeout(const Duration(seconds: 45));
    } on SocketException {
      throw NanoGptException(
        'Could not reach NanoGPT to load models. Check your internet.',
      );
    } on TimeoutException {
      throw NanoGptException('Loading models took too long. Try again.');
    } on http.ClientException {
      throw NanoGptException(
        'Could not reach NanoGPT to load models. Check your internet.',
      );
    }

    if (response.statusCode == 401) {
      throw NanoGptException(
        'NanoGPT rejected the API key while loading models.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NanoGptException(
        'Could not load models (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw NanoGptException('NanoGPT returned an unexpected models list.');
    }
    final data = decoded['data'];
    if (data is! List) {
      throw NanoGptException('NanoGPT returned an unexpected models list.');
    }

    final models = <NanoGptModelInfo>[];
    final seen = <String>{};
    for (final item in data) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final id = '${map['id'] ?? ''}'.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      models.add(NanoGptModelInfo.fromCatalogMap(map));
    }

    clearRuntimeStatsCache();
    models.sort((a, b) {
      final byOwner = NanoGptCatalogFilters.compareProviders(a.ownedBy, b.ownedBy);
      if (byOwner != 0) return byOwner;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return models;
  }

  Future<NanoGptCredits> getCredits() async {
    final headers = await _authHeaders();

    late final List<http.Response> responses;
    try {
      responses = await Future.wait([
        _http
            .post(
              Uri.parse('https://nano-gpt.com/api/check-balance'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 30)),
        _http
            .get(
              Uri.parse('https://nano-gpt.com/api/subscription/v1/usage'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 30)),
      ]);
    } on SocketException {
      throw NanoGptException(
        'Could not reach NanoGPT to check credits. Check your internet.',
      );
    } on TimeoutException {
      throw NanoGptException('Checking credits took too long. Try again.');
    } on http.ClientException {
      throw NanoGptException(
        'Could not reach NanoGPT to check credits. Check your internet.',
      );
    }

    final balanceResponse = responses[0];
    final subscriptionResponse = responses[1];
    if (balanceResponse.statusCode == 401 ||
        subscriptionResponse.statusCode == 401) {
      throw NanoGptException(
        'NanoGPT rejected the API key. Check the saved key in Settings.',
      );
    }

    Map<String, dynamic>? balance;
    Map<String, dynamic>? subscription;
    if (_isSuccess(balanceResponse.statusCode)) {
      balance = _decodeJsonMap(balanceResponse.body);
    }
    if (_isSuccess(subscriptionResponse.statusCode)) {
      subscription = _decodeJsonMap(subscriptionResponse.body);
    }
    if (balance == null && subscription == null) {
      throw NanoGptException(
        'NanoGPT could not return credit information right now.',
      );
    }

    final limits = _mapAt(subscription, 'limits');
    return NanoGptCredits(
      usdBalance: _numberAt(balance, 'usd_balance'),
      nanoBalance: _numberAt(balance, 'nano_balance'),
      subscriptionActive: subscription?['active'] == true,
      subscriptionState: '${subscription?['state'] ?? ''}'.trim(),
      weeklyTokens: _usageWindow(
        subscription,
        'weeklyInputTokens',
        limit: _numberAt(limits, 'weeklyInputTokens'),
      ),
      dailyTokens: _usageWindow(
            subscription,
            'dailyInputTokens',
            limit: _numberAt(limits, 'dailyInputTokens'),
          ) ??
          _usageWindow(
            subscription,
            'daily',
            limit: _numberAt(limits, 'daily'),
          ),
      dailyImages: _usageWindow(
        subscription,
        'dailyImages',
        limit: _numberAt(limits, 'dailyImages'),
      ),
      monthlyUsage: _usageWindow(
        subscription,
        'monthly',
        limit: _numberAt(limits, 'monthly'),
      ),
      currentPeriodEnd: _dateValue(
        _mapAt(subscription, 'period')?['currentPeriodEnd'],
      ),
      balanceUnavailable: balance == null,
      subscriptionUnavailable: subscription == null,
    );
  }

  Future<NanoGptModelRuntimeStats> fetchRuntimeStats(String modelId) async {
    final id = modelId.trim();
    if (id.isEmpty) return const NanoGptModelRuntimeStats();
    if (_runtimeCache.containsKey(id) && !_runtimeCache[id]!.isEmpty) {
      return _runtimeCache[id]!;
    }

    final uri = Uri.parse(
      'https://nano-gpt.com/api/models/${Uri.encodeComponent(id)}/providers',
    );
    try {
      final response = await _http
          .get(uri, headers: await _authHeaders(requireKey: false))
          .timeout(const Duration(seconds: 20));
      if (!_isSuccess(response.statusCode)) {
        return _runtimeCache[id] ?? const NanoGptModelRuntimeStats();
      }
      final map = _decodeJsonMap(response.body);
      if (map == null) {
        return _runtimeCache[id] ?? const NanoGptModelRuntimeStats();
      }
      final stats = NanoGptModelRuntimeStats.fromProvidersMap(map);
      _runtimeCache[id] = stats;
      return stats;
    } catch (_) {
      return _runtimeCache[id] ?? const NanoGptModelRuntimeStats();
    }
  }

  Future<void> prefetchRuntimeStats(
    Iterable<String> modelIds, {
    int maxConcurrent = 4,
  }) async {
    final queue = modelIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) => !_runtimeCache.containsKey(e) || _runtimeCache[e]!.isEmpty)
        .toList();
    if (queue.isEmpty) return;

    var index = 0;
    Future<void> worker() async {
      while (true) {
        if (index >= queue.length) return;
        final i = index++;
        await fetchRuntimeStats(queue[i]);
      }
    }

    final workers = <Future<void>>[];
    final count = maxConcurrent.clamp(1, 8);
    for (var i = 0; i < count; i++) {
      workers.add(worker());
    }
    await Future.wait(workers);
  }

  static bool _isSuccess(int code) => code >= 200 && code < 300;

  static Map<String, dynamic>? _decodeJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static Map<String, dynamic>? _mapAt(Map<String, dynamic>? map, String key) {
    final value = map?[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static double? _numberAt(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    final raw = map[key];
    if (raw is num) return raw.toDouble();
    return double.tryParse('$raw'.trim());
  }

  static DateTime? _dateValue(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        raw < 100000000000 ? raw * 1000 : raw,
        isUtc: true,
      );
    }
    return DateTime.tryParse('$raw');
  }

  static NanoGptUsageWindow? _usageWindow(
    Map<String, dynamic>? subscription,
    String key, {
    double? limit,
  }) {
    if (subscription == null) return null;
    final usage = _mapAt(subscription, 'usage') ?? subscription;
    final node = usage[key];
    if (node is Map) {
      final used = _numberAt(Map<String, dynamic>.from(node), 'used') ??
          _numberAt(Map<String, dynamic>.from(node), 'value') ??
          0;
      final rem = _numberAt(Map<String, dynamic>.from(node), 'remaining');
      final lim = _numberAt(Map<String, dynamic>.from(node), 'limit') ??
          limit ??
          (used + (rem ?? 0));
      return NanoGptUsageWindow(
        used: used,
        remaining: rem ?? (lim - used),
        limit: lim,
        resetAt: _dateValue(node['resetAt'] ?? node['resetsAt']),
      );
    }
    final used = _numberAt(usage, key);
    if (used == null && limit == null) return null;
    final lim = limit ?? 0;
    final u = used ?? 0;
    return NanoGptUsageWindow(
      used: u,
      remaining: lim - u,
      limit: lim,
    );
  }
}
