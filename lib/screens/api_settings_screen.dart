import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nanogpt_catalog.dart';
import '../providers/settings_provider.dart';
import '../services/secure_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/browse_models_sheet.dart';
import '../widgets/credits_sheet.dart';
import '../widgets/model_chips.dart';

class _LyricModelRec {
  const _LyricModelRec(this.label, this.id);
  final String label;
  final String id;
}

const _lyricModelRecs = <_LyricModelRec>[
  _LyricModelRec('DeepSeek V4 Pro (sub)', 'deepseek/deepseek-v4-pro'),
  _LyricModelRec('GLM 5.3 (sub)', 'z-ai/glm-5.3'),
  _LyricModelRec('Llama 4 Maverick (sub)', 'meta-llama/llama-4-maverick'),
  _LyricModelRec('Claude Sonnet 5.5', 'anthropic/claude-sonnet-5.5'),
  _LyricModelRec('Claude Opus 5.5', 'anthropic/claude-opus-5.5'),
];

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  late final TextEditingController _keyController;
  late final TextEditingController _modelController;
  late final FocusNode _modelFocus;
  bool _obscure = true;
  bool _subscriptionDraft = true;

  bool get _modelHasFocus => _modelFocus.hasFocus;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _keyController = TextEditingController();
    _modelController = TextEditingController(text: settings.model);
    _modelFocus = FocusNode();
    _subscriptionDraft = settings.useSubscription;
    if (settings.hasApiKey &&
        settings.catalog.isEmpty &&
        !settings.catalogLoading) {
      settings.refreshCatalog();
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _modelController.dispose();
    _modelFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    // Keep text field aligned when browse/favorites change the saved model.
    if (settings.model.isNotEmpty &&
        _modelController.text != settings.model &&
        !_modelHasFocus) {
      _modelController.value = TextEditingValue(
        text: settings.model,
        selection: TextSelection.collapsed(offset: settings.model.length),
      );
    }

    final filtered = settings.filteredCatalog;
    final categoryIds = NanoGptCatalogFilters.categoryFilterIds(settings.catalog);
    final providerIds = NanoGptCatalogFilters.providerFilterIds(
      NanoGptCatalogFilters.applyContext(
        NanoGptCatalogFilters.applyCategory(
          settings.catalog,
          settings.categoryFilter,
        ),
        settings.contextFilter,
      ),
    );
    final selected = settings.selectedModelInfo;

    return Scaffold(
      appBar: AppBar(title: const Text('API & connection')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'NanoGPT API key',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tagline stores the key with flutter_secure_storage. '
              'It is never committed or logged.',
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: settings.hasApiKey
                    ? 'Replace API key'
                    : 'NanoGPT API key',
                hintText: 'sk-nano-…',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(
                  onPressed: () async {
                    await settings.saveApiKey(_keyController.text);
                    _keyController.clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            settings.hasApiKey
                                ? 'API key saved'
                                : 'Enter a key before saving',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Save API key'),
                ),
                if (settings.hasApiKey)
                  OutlinedButton(
                    onPressed: () async {
                      await settings.clearApiKey();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved key removed')),
                        );
                      }
                    },
                    child: const Text('Remove saved key'),
                  ),
                Icon(
                  settings.hasApiKey
                      ? Icons.verified_user_outlined
                      : Icons.warning_amber_rounded,
                  color:
                      settings.hasApiKey ? AppColors.mint : AppColors.amber,
                  size: 20,
                ),
                Text(
                  settings.hasApiKey ? 'Key on file' : 'No key',
                  style: TextStyle(
                    color: settings.hasApiKey
                        ? AppColors.mint
                        : AppColors.amber,
                  ),
                ),
              ],
            ),

            if (settings.hasApiKey) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => showCreditsSheet(context),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('See remaining credits'),
              ),
            ],

            const SizedBox(height: 28),
            Text(
              'Use subscription API',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Subscription endpoint'),
              subtitle: Text(
                settings.useSubscription
                    ? SecureSettings.subscriptionBaseUrl
                    : SecureSettings.defaultBaseUrl,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              value: settings.useSubscription,
              activeThumbColor: AppColors.amber,
              onChanged: (v) async {
                setState(() => _subscriptionDraft = v);
                await settings.saveUseSubscription(v);
              },
            ),
            const Text(
              'On = subscription quota · Off = pay-as-you-go wallet. '
              'Changing this reloads the model catalog from the matching base URL.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AI model',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh catalog',
                  onPressed: settings.catalogLoading
                      ? null
                      : () => settings.refreshCatalog(),
                  icon: settings.catalogLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              settings.catalogLoading
                  ? 'Loading catalog…'
                  : settings.catalogError != null
                      ? settings.catalogError!
                      : settings.catalog.isEmpty
                          ? (settings.hasApiKey
                              ? 'No models loaded yet — tap refresh.'
                              : 'Save an API key to load the live catalog.')
                          : '${filtered.length} of ${settings.catalog.length} models · '
                              '${settings.filteredProviderCount} providers',
              style: TextStyle(
                color: settings.catalogError != null
                    ? AppColors.danger
                    : AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'NanoGPT’s website “Intelligence” score is not in the public API — '
              'chips below only show catalog + provider endpoint data.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.35),
            ),
            const SizedBox(height: 14),
            Text(
              'Recommended for Tagline lyrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap to fill the model field. Subscription picks are usually enough; '
              'use Claude when you want a quality ceiling.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rec in _lyricModelRecs)
                  ActionChip(
                    label: Text(rec.label),
                    tooltip: rec.id,
                    backgroundColor: settings.model == rec.id
                        ? AppColors.amber.withValues(alpha: 0.18)
                        : AppColors.inkSoft,
                    side: BorderSide(
                      color: settings.model == rec.id
                          ? AppColors.amber
                          : AppColors.line,
                    ),
                    onPressed: () {
                      _modelController.text = rec.id;
                      setState(() {});
                    },
                  ),
              ],
            ),

            if (settings.catalog.isNotEmpty) ...[
              const SizedBox(height: 14),
              _FilterDropdown(
                label: 'Category',
                value: settings.categoryFilter,
                items: {
                  for (final id in categoryIds)
                    id: NanoGptCatalogFilters.categoryLabel(id),
                },
                onChanged: settings.setCategoryFilter,
              ),
              const SizedBox(height: 10),
              _FilterDropdown(
                label: 'Min context',
                value: settings.contextFilter,
                items: const {
                  NanoGptCatalogFilters.contextAllId: 'Any context',
                  NanoGptCatalogFilters.context8kId: '≥ 8K',
                  NanoGptCatalogFilters.context16kId: '≥ 16K',
                  NanoGptCatalogFilters.context32kId: '≥ 32K',
                  NanoGptCatalogFilters.context128kId: '≥ 128K',
                },
                onChanged: settings.setContextFilter,
              ),
              const SizedBox(height: 10),
              _FilterDropdown(
                label: 'Provider',
                value: providerIds.contains(settings.providerFilter)
                    ? settings.providerFilter
                    : NanoGptCatalogFilters.allProviderId,
                items: {
                  for (final id in providerIds)
                    id: id == NanoGptCatalogFilters.allProviderId
                        ? 'All providers'
                        : id,
                },
                onChanged: settings.setProviderFilter,
              ),
            ],

            if (settings.favorites.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Favorites', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final fav in settings.favorites)
                    InputChip(
                      avatar: const Icon(Icons.star, size: 16),
                      label: Text(fav.display),
                      selected: settings.model == fav.id,
                      onSelected: (_) {
                        _modelController.text = fav.id;
                        settings.saveModel(fav.id);
                      },
                      onDeleted: () => settings.toggleFavoriteId(
                        fav.id,
                        label: fav.label,
                        provider: fav.provider,
                      ),
                    ),
                ],
              ),
            ],

            if (selected != null) ...[
              const SizedBox(height: 16),
              _SelectedModelCard(
                model: selected,
                runtime: settings.selectedRuntime,
                isFavorite: settings.isFavorite(selected.id),
                onFavorite: () => settings.toggleFavoriteFor(selected),
                onBrowse: () => showBrowseModelsSheet(context),
              ),
            ] else if (settings.catalog.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => showBrowseModelsSheet(context),
                icon: const Icon(Icons.list_alt),
                label: const Text('Browse models'),
              ),
            ],

            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              focusNode: _modelFocus,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Model ID',
                hintText: 'openai/gpt-4o',
                helperText: 'Dropdowns fill this field; custom ids are allowed',
                suffixIcon: IconButton(
                  tooltip: settings.isFavorite(_modelController.text.trim())
                      ? 'Unfavorite'
                      : 'Favorite',
                  icon: Icon(
                    settings.isFavorite(_modelController.text.trim())
                        ? Icons.star
                        : Icons.star_border,
                    color: AppColors.amber,
                  ),
                  onPressed: () {
                    final id = _modelController.text.trim();
                    if (id.isEmpty) return;
                    NanoGptModelInfo? info;
                    for (final m in settings.catalog) {
                      if (m.id == id) {
                        info = m;
                        break;
                      }
                    }
                    settings.toggleFavoriteId(
                      id,
                      label: info?.displayName ?? id,
                      provider: info?.ownedBy ?? '',
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await settings.saveModelAndConnection(
                  modelId: _modelController.text,
                  subscription: _subscriptionDraft,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Model & connection saved'),
                    ),
                  );
                }
              },
              child: const Text('Save model & connection'),
            ),

            const SizedBox(height: 36),
            Text('About Tagline', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Expert Suno pre-production: multi-pass lyrics + style prompts. '
              'Connection settings mirror Anima’s NanoGPT UX.',
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = items.containsKey(value) ? value : items.keys.first;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: safeValue,
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

class _SelectedModelCard extends StatelessWidget {
  const _SelectedModelCard({
    required this.model,
    required this.runtime,
    required this.isFavorite,
    required this.onFavorite,
    required this.onBrowse,
  });

  final NanoGptModelInfo model;
  final NanoGptModelRuntimeStats? runtime;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final statLabels = <String>[
      if (model.contextLabel != null) model.contextLabel!,
      if (model.maxOutputLabel != null) model.maxOutputLabel!,
      if (model.parameterLabel != null) model.parameterLabel!,
      if (model.subscriptionIncluded) 'Included',
      if (runtime?.tpsLabel != null) runtime!.tpsLabel!,
      if (runtime?.ttftLabel != null) runtime!.ttftLabel!,
      if (runtime?.uptimeLabel != null) runtime!.uptimeLabel!,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inkElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      model.id,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavorite,
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          if (statLabels.isNotEmpty) ...[
            const SizedBox(height: 8),
            ModelChipWrap(labels: statLabels),
          ],
          if (model.capabilities.shortLabels.isNotEmpty) ...[
            const SizedBox(height: 8),
            ModelChipWrap(labels: model.capabilities.shortLabels),
          ],
          if (model.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              model.description.trim(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
          if (model.pricingLine != null) ...[
            const SizedBox(height: 8),
            Text(
              model.pricingLine!,
              style: const TextStyle(fontSize: 12.5, color: AppColors.mint),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onBrowse,
            icon: const Icon(Icons.list_alt, size: 18),
            label: const Text('Browse models'),
          ),
        ],
      ),
    );
  }
}
