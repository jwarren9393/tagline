import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Dropdown-looking field that opens a searchable sheet with favorites + A–Z.
class FavoritePickerField extends StatelessWidget {
  const FavoritePickerField({
    super.key,
    required this.label,
    required this.valueText,
    required this.onOpen,
    this.hint = 'Choose…',
  });

  final String label;
  final String valueText;
  final String hint;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final empty = valueText.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Material(
          color: AppColors.inkElevated,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onOpen,
            child: InputDecorator(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                empty ? hint : valueText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: empty ? AppColors.textMuted : AppColors.text,
                  fontSize: 14.5,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FavoritePickerItem {
  const FavoritePickerItem({
    required this.id,
    required this.label,
    required this.isFavorite,
  });

  final String id;
  final String label;
  final bool isFavorite;
}

Future<T?> showFavoritePickerSheet<T>({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<FavoritePickerItem> items,
  required Set<String> selectedIds,
  required bool multiSelect,
  required Future<void> Function(String id) onToggleFavorite,
  String? noneId,
  String noneLabel = 'None',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.inkElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return _FavoritePickerSheet(
        title: title,
        subtitle: subtitle,
        items: items,
        selectedIds: selectedIds,
        multiSelect: multiSelect,
        onToggleFavorite: onToggleFavorite,
        noneId: noneId,
        noneLabel: noneLabel,
      );
    },
  );
}

class _FavoritePickerSheet extends StatefulWidget {
  const _FavoritePickerSheet({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedIds,
    required this.multiSelect,
    required this.onToggleFavorite,
    this.noneId,
    this.noneLabel = 'None',
  });

  final String title;
  final String subtitle;
  final List<FavoritePickerItem> items;
  final Set<String> selectedIds;
  final bool multiSelect;
  final Future<void> Function(String id) onToggleFavorite;
  final String? noneId;
  final String noneLabel;

  @override
  State<_FavoritePickerSheet> createState() => _FavoritePickerSheetState();
}

class _FavoritePickerSheetState extends State<_FavoritePickerSheet> {
  late Set<String> _selected;
  late List<FavoritePickerItem> _items;
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.selectedIds);
    _items = List<FavoritePickerItem>.from(widget.items);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<FavoritePickerItem> get _filtered {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((i) => i.label.toLowerCase().contains(q)).toList();
  }

  Future<void> _star(FavoritePickerItem item) async {
    await widget.onToggleFavorite(item.id);
    setState(() {
      _items = _items
          .map(
            (i) => i.id == item.id
                ? FavoritePickerItem(
                    id: i.id,
                    label: i.label,
                    isFavorite: !i.isFavorite,
                  )
                : i,
          )
          .toList()
        ..sort((a, b) {
          if (a.isFavorite != b.isFavorite) {
            return a.isFavorite ? -1 : 1;
          }
          return a.label.toLowerCase().compareTo(b.label.toLowerCase());
        });
    });
  }

  void _pick(String id) {
    if (widget.multiSelect) {
      setState(() {
        if (_selected.contains(id)) {
          _selected.remove(id);
        } else {
          _selected.add(id);
        }
      });
    } else {
      Navigator.of(context).pop(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.75;
    final filtered = _filtered;
    final favCount = filtered.where((i) => i.isFavorite).length;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.multiSelect)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(
                        Set<String>.from(_selected),
                      ),
                      child: const Text('Done'),
                    )
                  else
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (!widget.multiSelect && widget.noneId != null)
              ListTile(
                leading: Icon(
                  _selected.isEmpty || _selected.contains(widget.noneId)
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.amber,
                ),
                title: Text(widget.noneLabel),
                onTap: () => Navigator.of(context).pop(widget.noneId),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final showHeader = index == 0 ||
                      (index == favCount && favCount > 0);
                  final sectionLabel = index == 0 && item.isFavorite
                      ? 'Favorites'
                      : (index == favCount && favCount > 0 && !item.isFavorite)
                          ? 'All'
                          : null;

                  final selected = _selected.contains(item.id);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showHeader && sectionLabel != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                          child: Text(
                            sectionLabel,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ListTile(
                        leading: widget.multiSelect
                            ? Icon(
                                selected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: selected
                                    ? AppColors.amber
                                    : AppColors.textMuted,
                              )
                            : Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selected
                                    ? AppColors.amber
                                    : AppColors.textMuted,
                              ),
                        title: Text(item.label),
                        trailing: IconButton(
                          tooltip: item.isFavorite
                              ? 'Remove favorite'
                              : 'Favorite (pin to top)',
                          onPressed: () => _star(item),
                          icon: Icon(
                            item.isFavorite ? Icons.star : Icons.star_border,
                            color: item.isFavorite
                                ? AppColors.amber
                                : AppColors.textMuted,
                          ),
                        ),
                        onTap: () => _pick(item.id),
                      ),
                    ],
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
