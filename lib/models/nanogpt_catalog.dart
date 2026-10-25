// NanoGPT text-model catalog types + filter/sort helpers (Anima-parity UX).

class NanoGptModelCapabilities {
  const NanoGptModelCapabilities({
    this.vision = false,
    this.reasoning = false,
    this.toolCalling = false,
    this.parallelToolCalls = false,
    this.structuredOutput = false,
    this.pdfUpload = false,
    this.videoInput = false,
    this.audioInput = false,
  });

  final bool vision;
  final bool reasoning;
  final bool toolCalling;
  final bool parallelToolCalls;
  final bool structuredOutput;
  final bool pdfUpload;
  final bool videoInput;
  final bool audioInput;

  static NanoGptModelCapabilities parse(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const NanoGptModelCapabilities();
    return NanoGptModelCapabilities(
      vision: map['vision'] == true,
      reasoning: map['reasoning'] == true,
      toolCalling: map['tool_calling'] == true,
      parallelToolCalls: map['parallel_tool_calls'] == true,
      structuredOutput: map['structured_output'] == true,
      pdfUpload: map['pdf_upload'] == true,
      videoInput: map['video_input'] == true,
      audioInput: map['audio_input'] == true,
    );
  }

  List<String> get shortLabels {
    final labels = <String>[];
    if (vision) labels.add('Vision');
    if (videoInput) labels.add('Video');
    if (audioInput) labels.add('Audio');
    if (reasoning) labels.add('Reasoning');
    if (toolCalling) labels.add('Tools');
    if (structuredOutput) labels.add('JSON');
    if (pdfUpload) labels.add('PDF');
    return labels;
  }
}

class NanoGptModelRuntimeStats {
  const NanoGptModelRuntimeStats({this.tps, this.ttftMs, this.uptimePercent});

  final double? tps;
  final double? ttftMs;
  final int? uptimePercent;

  bool get isEmpty => tps == null && ttftMs == null && uptimePercent == null;

  String? get tpsLabel {
    final v = tps;
    if (v == null || v <= 0) return null;
    return v >= 10 ? '${v.round()} TPS' : '${v.toStringAsFixed(1)} TPS';
  }

  String? get ttftLabel {
    final ms = ttftMs;
    if (ms == null || ms <= 0) return null;
    if (ms < 1000) return '${ms.round()}ms TTFT';
    final seconds = ms / 1000;
    return seconds == seconds.roundToDouble()
        ? '${seconds.round()}s TTFT'
        : '${seconds.toStringAsFixed(1)}s TTFT';
  }

  String? get uptimeLabel {
    final value = uptimePercent;
    if (value == null) return null;
    return '$value% up';
  }

  static NanoGptModelRuntimeStats fromProvidersMap(Map<String, dynamic> map) {
    final tps = _positiveDouble(map['autoTps']);
    final ttftMs = _positiveDouble(map['autoTtftMs']);
    int? uptimePercent;
    final providers = map['providers'];
    if (providers is List && providers.isNotEmpty) {
      var available = 0;
      for (final item in providers) {
        if (item is Map && item['available'] == true) available++;
      }
      uptimePercent = ((available / providers.length) * 100).round();
    }
    return NanoGptModelRuntimeStats(
      tps: tps,
      ttftMs: ttftMs,
      uptimePercent: uptimePercent,
    );
  }

  static double? _positiveDouble(dynamic value) {
    if (value is num) {
      final n = value.toDouble();
      return n > 0 ? n : null;
    }
    final parsed = double.tryParse('$value'.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}

class NanoGptModelInfo {
  const NanoGptModelInfo({
    required this.id,
    required this.ownedBy,
    required this.name,
    this.contextLength,
    this.maxOutputTokens,
    this.category,
    this.description = '',
    this.subscriptionIncluded = false,
    this.capabilities = const NanoGptModelCapabilities(),
    this.openWeights = false,
    this.pricingPromptPerMillion,
    this.pricingCompletionPerMillion,
    this.costEstimateUsd,
    this.created,
    this.parameterSizeLabel,
  });

  final String id;
  final String ownedBy;
  final String name;
  final int? contextLength;
  final int? maxOutputTokens;
  final String? category;
  final String description;
  final bool subscriptionIncluded;
  final NanoGptModelCapabilities capabilities;
  final bool openWeights;
  final double? pricingPromptPerMillion;
  final double? pricingCompletionPerMillion;
  final double? costEstimateUsd;
  final int? created;
  final String? parameterSizeLabel;

  static final RegExp uncensoredNameHeuristic = RegExp(
    r'abliterat|uncensor|derestrict|de-restrict|unfiltered|unrestricted',
    caseSensitive: false,
  );

  static const autoProviderLabel = 'Auto';

  String get displayName => name.trim().isEmpty ? id : name.trim();

  bool get isUncensoredCategory {
    final cat = category?.trim().toLowerCase() ?? '';
    return cat.contains('uncensor');
  }

  bool get isUncensoredFriendly =>
      isUncensoredCategory ||
      uncensoredNameHeuristic.hasMatch('$id $displayName $description');

  static bool isAutoModelId(String id) {
    final lower = id.trim().toLowerCase();
    return lower == 'auto-model' || lower.startsWith('auto-model-');
  }

  static bool isAutoProvider(String ownedBy) {
    final lower = ownedBy.trim().toLowerCase();
    return lower == 'auto' ||
        lower == 'auto-model' ||
        lower.startsWith('auto-model');
  }

  static String formatTokenCount(int tokens) {
    final n = tokens < 0 ? 0 : tokens;
    if (n < 1000) return '$n';
    if (n < 10000) {
      final k = n / 1000;
      final text =
          k == k.roundToDouble() ? '${k.round()}' : k.toStringAsFixed(1);
      return '${text}K';
    }
    if (n < 1000000) return '${(n / 1000).round()}K';
    final m = n / 1000000;
    final text = m == m.roundToDouble() ? '${m.round()}' : m.toStringAsFixed(1);
    return '${text}M';
  }

  String? get contextLabel {
    final n = contextLength;
    if (n == null || n <= 0) return null;
    return '${formatTokenCount(n)} ctx';
  }

  String? get maxOutputLabel {
    final n = maxOutputTokens;
    if (n == null || n <= 0) return null;
    return '${formatTokenCount(n)} out';
  }

  String? get parameterLabel {
    final label = parameterSizeLabel?.trim();
    if (label == null || label.isEmpty) return null;
    return label;
  }

  String get displayNameWithContext {
    final ctx = contextLabel;
    if (ctx == null) return displayName;
    return '$displayName · $ctx';
  }

  String statChipLine({NanoGptModelRuntimeStats? runtime}) {
    final parts = <String>[];
    final ctx = contextLabel;
    if (ctx != null) parts.add(ctx);
    final out = maxOutputLabel;
    if (out != null) parts.add(out);
    final params = parameterLabel;
    if (params != null) parts.add(params);
    if (runtime != null) {
      final tps = runtime.tpsLabel;
      if (tps != null) parts.add(tps);
      final ttft = runtime.ttftLabel;
      if (ttft != null) parts.add(ttft);
      final uptime = runtime.uptimeLabel;
      if (uptime != null) parts.add(uptime);
    }
    if (subscriptionIncluded) parts.add('Included');
    final cat = category?.trim();
    if (cat != null && cat.isNotEmpty) parts.add(cat);
    return parts.join(' · ');
  }

  String? get pricingLine {
    if (subscriptionIncluded) return 'Included in subscription';
    final prompt = pricingPromptPerMillion;
    final completion = pricingCompletionPerMillion;
    if (prompt != null && completion != null) {
      return 'Input ${formatUsd(prompt)} · Output ${formatUsd(completion)} per 1M tokens';
    }
    if (costEstimateUsd != null) {
      return 'Est. ${formatUsd(costEstimateUsd!)} / message';
    }
    return null;
  }

  static String formatUsd(double value) {
    if (value >= 0.01) return '\$${value.toStringAsFixed(2)}';
    return '\$${value.toStringAsFixed(4)}';
  }

  static int? parseContextLength(Map<String, dynamic> map) {
    return _positiveInt(
      map['context_length'] ??
          map['contextLength'] ??
          map['max_context'] ??
          map['maxContext'] ??
          map['context_window'] ??
          map['contextWindow'],
    );
  }

  static int? parseMaxOutputTokens(Map<String, dynamic> map) {
    return _positiveInt(
      map['max_output_tokens'] ??
          map['maxOutputTokens'] ??
          map['max_tokens'] ??
          map['maxTokens'],
    );
  }

  static int? _positiveInt(dynamic value) {
    if (value is int) return value > 0 ? value : null;
    if (value is num) {
      final n = value.round();
      return n > 0 ? n : null;
    }
    final parsed = int.tryParse('$value'.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static bool parseSubscriptionIncluded(Map<String, dynamic> map) {
    final sub = map['subscription'];
    if (sub is Map) return sub['included'] == true;
    return false;
  }

  static String? parseCategory(Map<String, dynamic> map) {
    final raw = '${map['category'] ?? ''}'.trim();
    return raw.isEmpty ? null : raw;
  }

  static double? parseCostEstimateUsd(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || RegExp(r'^\$+$').hasMatch(trimmed)) return null;
      return double.tryParse(trimmed.replaceAll(r'$', ''));
    }
    return null;
  }

  static double? parsePricingPerMillion(Map<String, dynamic> map, String key) {
    final pricing = map['pricing'];
    if (pricing is! Map) return null;
    final raw = pricing[key];
    if (raw is num) return raw.toDouble();
    return double.tryParse('$raw'.trim());
  }

  static int? parseCreated(Map<String, dynamic> map) {
    final raw = map['created'];
    if (raw is int && raw > 0) return raw;
    if (raw is num) return raw.round();
    return int.tryParse('$raw'.trim());
  }

  static String? inferParameterSizeLabel({
    required String id,
    required String name,
    String description = '',
  }) {
    final sizes = <({double amount, String unit})>[];
    final pattern = RegExp(r'(?<![\d.])(\d+(?:\.\d+)?)\s*([Bb])(?![a-z])');
    void scan(String text) {
      for (final match in pattern.allMatches(text)) {
        final amount = double.tryParse(match.group(1) ?? '');
        if (amount == null || amount <= 0) continue;
        sizes.add((amount: amount, unit: (match.group(2) ?? 'B').toUpperCase()));
      }
    }

    scan(name);
    scan(id);
    scan(description);
    if (sizes.isEmpty) return null;
    sizes.sort((a, b) => b.amount.compareTo(a.amount));
    final best = sizes.first;
    final amountText = best.amount == best.amount.roundToDouble()
        ? '${best.amount.round()}'
        : best.amount.toStringAsFixed(1);
    return '$amountText${best.unit}';
  }

  static NanoGptModelInfo fromCatalogMap(Map<String, dynamic> map) {
    final id = '${map['id'] ?? ''}'.trim();
    final rawOwner = '${map['owned_by'] ?? 'other'}'.trim();
    final name = '${map['name'] ?? ''}'.trim();
    final description = '${map['description'] ?? ''}'.trim();
    final ownedBy = isAutoModelId(id)
        ? autoProviderLabel
        : (rawOwner.isEmpty ? 'other' : rawOwner);
    final displayName = name.isEmpty ? id : name;
    return NanoGptModelInfo(
      id: id,
      ownedBy: ownedBy,
      name: displayName,
      contextLength: parseContextLength(map),
      maxOutputTokens: parseMaxOutputTokens(map),
      category: parseCategory(map),
      description: description,
      subscriptionIncluded: parseSubscriptionIncluded(map),
      capabilities: NanoGptModelCapabilities.parse(
        map['capabilities'] is Map
            ? Map<String, dynamic>.from(map['capabilities'] as Map)
            : null,
      ),
      openWeights: map['open_weights'] == true,
      pricingPromptPerMillion: parsePricingPerMillion(map, 'prompt'),
      pricingCompletionPerMillion: parsePricingPerMillion(map, 'completion'),
      costEstimateUsd: parseCostEstimateUsd(map['cost_estimate']),
      created: parseCreated(map),
      parameterSizeLabel: inferParameterSizeLabel(
        id: id,
        name: displayName,
        description: description,
      ),
    );
  }
}

class NanoGptUsageWindow {
  const NanoGptUsageWindow({
    required this.used,
    required this.remaining,
    required this.limit,
    this.resetAt,
  });

  final double used;
  final double remaining;
  final double limit;
  final DateTime? resetAt;

  double get percentUsed => limit <= 0 ? 0 : (used / limit).clamp(0, 1);
}

class NanoGptCredits {
  const NanoGptCredits({
    this.usdBalance,
    this.nanoBalance,
    this.subscriptionActive = false,
    this.subscriptionState = '',
    this.weeklyTokens,
    this.dailyTokens,
    this.dailyImages,
    this.monthlyUsage,
    this.currentPeriodEnd,
    this.balanceUnavailable = false,
    this.subscriptionUnavailable = false,
  });

  final double? usdBalance;
  final double? nanoBalance;
  final bool subscriptionActive;
  final String subscriptionState;
  final NanoGptUsageWindow? weeklyTokens;
  final NanoGptUsageWindow? dailyTokens;
  final NanoGptUsageWindow? dailyImages;
  final NanoGptUsageWindow? monthlyUsage;
  final DateTime? currentPeriodEnd;
  final bool balanceUnavailable;
  final bool subscriptionUnavailable;
}

class NanoGptCatalogFilters {
  const NanoGptCatalogFilters._();

  static const allCategoryId = '__all__';
  static const uncensoredFriendlyId = '__uncensored_friendly__';
  static const uncensoredFriendlyLabel = 'Uncensored & derestricted (broad)';

  static const contextAllId = '__ctx_all__';
  static const context8kId = '__ctx_8k__';
  static const context16kId = '__ctx_16k__';
  static const context32kId = '__ctx_32k__';
  static const context128kId = '__ctx_128k__';

  static const allProviderId = '__provider_all__';

  static String categoryLabel(String id) {
    if (id == allCategoryId) return 'All categories';
    if (id == uncensoredFriendlyId) return uncensoredFriendlyLabel;
    return id;
  }

  static String contextLabel(String id) => switch (id) {
        contextAllId => 'Any context',
        context8kId => '≥ 8K',
        context16kId => '≥ 16K',
        context32kId => '≥ 32K',
        context128kId => '≥ 128K',
        _ => 'Any context',
      };

  static List<String> categoryFilterIds(List<NanoGptModelInfo> models) {
    final categories = <String>{};
    for (final model in models) {
      final cat = model.category?.trim();
      if (cat != null && cat.isNotEmpty) categories.add(cat);
    }
    final sorted = categories.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return [allCategoryId, uncensoredFriendlyId, ...sorted];
  }

  static List<String> providerFilterIds(List<NanoGptModelInfo> models) {
    final providers = <String>{};
    for (final m in models) {
      providers.add(m.ownedBy);
    }
    final list = providers.toList();
    list.sort(compareProviders);
    return [allProviderId, ...list];
  }

  static int compareProviders(String a, String b) {
    final aAuto = NanoGptModelInfo.isAutoProvider(a);
    final bAuto = NanoGptModelInfo.isAutoProvider(b);
    if (aAuto != bAuto) return aAuto ? -1 : 1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  static List<NanoGptModelInfo> applyCategory(
    List<NanoGptModelInfo> models,
    String filterId,
  ) {
    if (filterId == allCategoryId) return models;
    if (filterId == uncensoredFriendlyId) {
      return [for (final m in models) if (m.isUncensoredFriendly) m];
    }
    return [for (final m in models) if (m.category?.trim() == filterId) m];
  }

  static int? minContextTokens(String filterId) => switch (filterId) {
        context8kId => 8000,
        context16kId => 16000,
        context32kId => 32000,
        context128kId => 128000,
        _ => null,
      };

  static List<NanoGptModelInfo> applyContext(
    List<NanoGptModelInfo> models,
    String filterId,
  ) {
    final min = minContextTokens(filterId);
    if (min == null) return models;
    return [
      for (final m in models)
        if ((m.contextLength ?? 0) >= min) m,
    ];
  }

  static List<NanoGptModelInfo> applyProvider(
    List<NanoGptModelInfo> models,
    String filterId,
  ) {
    if (filterId == allProviderId) return models;
    return [for (final m in models) if (m.ownedBy == filterId) m];
  }

  static List<NanoGptModelInfo> applyPipeline({
    required List<NanoGptModelInfo> models,
    required String categoryId,
    required String contextId,
    required String providerId,
  }) {
    var out = applyCategory(models, categoryId);
    out = applyContext(out, contextId);
    out = applyProvider(out, providerId);
    return out;
  }
}

enum TextModelSortMode { name, contextDesc, tpsDesc, ttftAsc, costAsc }

extension TextModelSortModeX on TextModelSortMode {
  String get label => switch (this) {
        TextModelSortMode.name => 'Name',
        TextModelSortMode.contextDesc => 'Largest context',
        TextModelSortMode.tpsDesc => 'Fastest (TPS)',
        TextModelSortMode.ttftAsc => 'Lowest TTFT',
        TextModelSortMode.costAsc => 'Lowest cost',
      };
}
