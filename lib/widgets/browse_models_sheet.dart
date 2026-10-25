import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nanogpt_catalog.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'model_chips.dart';

Future<void> showBrowseModelsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.inkElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => const _BrowseModelsSheet(),
  );
}

class _BrowseModelsSheet extends StatefulWidget {
  const _BrowseModelsSheet();

  @override
  State<_BrowseModelsSheet> createState() => _BrowseModelsSheetState();
}

class _BrowseModelsSheetState extends State<_BrowseModelsSheet> {
  final _search = TextEditingController();
  String _contextId = NanoGptCatalogFilters.contextAllId;
  String _tpsId = '__tps_all__';
  String _ttftId = '__ttft_all__';
  TextModelSortMode _sort = TextModelSortMode.name;
  bool _favoritesOnly = false;
  bool _warming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmStats());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _warmStats() async {
    final settings = context.read<SettingsProvider>();
    final ids = settings.filteredCatalog.take(40).map((m) => m.id);
    setState(() => _warming = true);
    await settings.catalogService.prefetchRuntimeStats(ids);
    if (mounted) setState(() => _warming = false);
  }

  List<NanoGptModelInfo> _visible(SettingsProvider settings) {
    var list = List<NanoGptModelInfo>.from(settings.filteredCatalog);
    final q = _search.text.trim().toLowerCase();
    if (_favoritesOnly) {
      final fav = settings.favorites.map((f) => f.id).toSet();
      list = [for (final m in list) if (fav.contains(m.id)) m];
    }
    if (q.isNotEmpty) {
      list = [
        for (final m in list)
          if ('${m.id} ${m.displayName} ${m.description} ${m.ownedBy}'
              .toLowerCase()
              .contains(q))
            m,
      ];
    }
    list = NanoGptCatalogFilters.applyContext(list, _contextId);

    final minTps = switch (_tpsId) {
      '__tps_20__' => 20.0,
      '__tps_40__' => 40.0,
      '__tps_60__' => 60.0,
      _ => null,
    };
    final maxTtft = switch (_ttftId) {
      '__ttft_500__' => 500.0,
      '__ttft_1000__' => 1000.0,
      '__ttft_2000__' => 2000.0,
      _ => null,
    };
    if (minTps != null || maxTtft != null) {
      list = [
        for (final m in list)
          if (_passesRuntime(
            settings.catalogService.cachedRuntimeStats(m.id),
            minTps: minTps,
            maxTtft: maxTtft,
          ))
            m,
      ];
    }

    list.sort((a, b) {
      switch (_sort) {
        case TextModelSortMode.name:
          return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
        case TextModelSortMode.contextDesc:
          return (b.contextLength ?? 0).compareTo(a.contextLength ?? 0);
        case TextModelSortMode.tpsDesc:
          final av = settings.catalogService.cachedRuntimeStats(a.id).tps;
          final bv = settings.catalogService.cachedRuntimeStats(b.id).tps;
          if (av == null && bv == null) return a.id.compareTo(b.id);
          if (av == null) return 1;
          if (bv == null) return -1;
          return bv.compareTo(av);
        case TextModelSortMode.ttftAsc:
          final av = settings.catalogService.cachedRuntimeStats(a.id).ttftMs;
          final bv = settings.catalogService.cachedRuntimeStats(b.id).ttftMs;
          if (av == null && bv == null) return a.id.compareTo(b.id);
          if (av == null) return 1;
          if (bv == null) return -1;
          return av.compareTo(bv);
        case TextModelSortMode.costAsc:
          final av = a.pricingPromptPerMillion ?? double.infinity;
          final bv = b.pricingPromptPerMillion ?? double.infinity;
          return av.compareTo(bv);
      }
    });
    return list;
  }

  bool _passesRuntime(
    NanoGptModelRuntimeStats stats, {
    required double? minTps,
    required double? maxTtft,
  }) {
    if (minTps != null) {
      final tps = stats.tps;
      if (tps != null && tps < minTps) return false;
    }
    if (maxTtft != null) {
      final ttft = stats.ttftMs;
      if (ttft != null && ttft > maxTtft) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final models = _visible(settings);
    final height = MediaQuery.sizeOf(context).height * 0.88;

    return SizedBox(
      height: height,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Browse models',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (_warming)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search name, id, description…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('⭐ Favorites'),
                    selected: _favoritesOnly,
                    onSelected: (v) => setState(() => _favoritesOnly = v),
                  ),
                  const SizedBox(width: 8),
                  _MiniDropdown(
                    value: _contextId,
                    items: const {
                      NanoGptCatalogFilters.contextAllId: 'Any ctx',
                      NanoGptCatalogFilters.context8kId: '≥8K',
                      NanoGptCatalogFilters.context16kId: '≥16K',
                      NanoGptCatalogFilters.context32kId: '≥32K',
                      NanoGptCatalogFilters.context128kId: '≥128K',
                    },
                    onChanged: (v) => setState(() => _contextId = v),
                  ),
                  const SizedBox(width: 8),
                  _MiniDropdown(
                    value: _tpsId,
                    items: const {
                      '__tps_all__': 'Any TPS',
                      '__tps_20__': '≥20 TPS',
                      '__tps_40__': '≥40 TPS',
                      '__tps_60__': '≥60 TPS',
                    },
                    onChanged: (v) => setState(() => _tpsId = v),
                  ),
                  const SizedBox(width: 8),
                  _MiniDropdown(
                    value: _ttftId,
                    items: const {
                      '__ttft_all__': 'Any TTFT',
                      '__ttft_500__': '≤500ms',
                      '__ttft_1000__': '≤1s',
                      '__ttft_2000__': '≤2s',
                    },
                    onChanged: (v) => setState(() => _ttftId = v),
                  ),
                  const SizedBox(width: 8),
                  _MiniDropdown(
                    value: _sort.name,
                    items: {
                      for (final m in TextModelSortMode.values) m.name: m.label,
                    },
                    onChanged: (v) => setState(() {
                      _sort = TextModelSortMode.values
                          .firstWhere((e) => e.name == v);
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${models.length} models',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: models.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final m = models[index];
                  final runtime =
                      settings.catalogService.cachedRuntimeStats(m.id);
                  final selected = settings.model == m.id;
                  final fav = settings.isFavorite(m.id);
                  return ListTile(
                    selected: selected,
                    title: Text(m.displayName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.id,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.statChipLine(runtime: runtime),
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (m.capabilities.shortLabels.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          ModelChipWrap(labels: m.capabilities.shortLabels),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: Icon(
                        fav ? Icons.star : Icons.star_border,
                        color: fav ? AppColors.amber : AppColors.textMuted,
                      ),
                      onPressed: () => settings.toggleFavoriteFor(m),
                    ),
                    onTap: () async {
                      await settings.saveModel(m.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDropdown extends StatelessWidget {
  const _MiniDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.containsKey(value) ? value : items.keys.first,
          items: [
            for (final e in items.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
