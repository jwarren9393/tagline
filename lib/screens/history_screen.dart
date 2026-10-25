import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/generation_session.dart';
import '../providers/generation_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GenerationProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gen = context.watch<GenerationProvider>();
    final sessions = gen.filteredHistory;
    final tags = gen.allHistoryTags.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Import session file',
            onPressed: () async {
              try {
                final count = await gen.importSessionsFromFile();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count == 0
                          ? 'Import cancelled'
                          : 'Imported $count session${count == 1 ? '' : 's'}',
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$e'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: 'Export all history',
            onPressed: gen.history.isEmpty
                ? null
                : () async {
                    try {
                      final outcome = await gen.exportFullHistory(
                        sharePositionOrigin: shareOriginFromContext(context),
                      );
                      if (!context.mounted || outcome.isCancelled) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            outcome.kind == ShareOutcomeKind.saved
                                ? 'History saved to ${outcome.path}'
                                : 'History backup ready to send',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$e'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.file_upload_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: !gen.historyLoaded
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _search,
                      onChanged: gen.setHistoryQuery,
                      decoration: InputDecoration(
                        hintText: 'Search prompts, lyrics, tags…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: gen.historyQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _search.clear();
                                  gen.setHistoryQuery('');
                                },
                              ),
                      ),
                    ),
                  ),
                  if (tags.isNotEmpty)
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: gen.historyTagFilter == null,
                              onSelected: (_) => gen.setHistoryTagFilter(null),
                            ),
                          ),
                          ...tags.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(t),
                                selected: gen.historyTagFilter == t,
                                onSelected: (v) =>
                                    gen.setHistoryTagFilter(v ? t : null),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: gen.history.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No saved generations yet.\n'
                                'Successful runs are saved automatically.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          )
                        : sessions.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matches.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: sessions.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final session = sessions[index];
                                  return _HistoryTile(
                                    session: session,
                                    onOpen: () {
                                      gen.openSession(session);
                                      Navigator.of(context).pop();
                                    },
                                    onReusePrompt: () {
                                      gen.reusePromptFromSession(session);
                                      Navigator.of(context).pop();
                                    },
                                    onExport: () async {
                                      try {
                                        final outcome = await gen.exportSession(
                                          session,
                                          sharePositionOrigin:
                                              shareOriginFromContext(context),
                                        );
                                        if (!context.mounted ||
                                            outcome.isCancelled) {
                                          return;
                                        }
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              outcome.kind ==
                                                      ShareOutcomeKind.saved
                                                  ? 'Exported to ${outcome.path}'
                                                  : 'Session file ready to send',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('$e'),
                                            backgroundColor: AppColors.danger,
                                          ),
                                        );
                                      }
                                    },
                                    onPin: () => gen.togglePin(session),
                                    onDelete: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title:
                                              const Text('Delete generation?'),
                                          content: Text(
                                            'Remove “${session.displayTitle}”?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok == true) {
                                        await gen.deleteSession(session.id);
                                      }
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.session,
    required this.onOpen,
    required this.onReusePrompt,
    required this.onExport,
    required this.onPin,
    required this.onDelete,
  });

  final GenerationSession session;
  final VoidCallback onOpen;
  final VoidCallback onReusePrompt;
  final VoidCallback onExport;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final eval = session.evalSummary;
    return Material(
      color: AppColors.inkElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    session.pinned ? Icons.push_pin : Icons.music_note_outlined,
                    color:
                        session.pinned ? AppColors.amber : AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.displayTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.idea.rawIdea.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              _formatDate(session.updatedAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (session.idea.genre != null)
                              Text(
                                session.idea.genre!.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.amber,
                                ),
                              ),
                            if (eval != null)
                              Text(
                                eval.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: eval.ratio >= 0.85
                                      ? AppColors.mint
                                      : AppColors.amber,
                                ),
                              ),
                            ...session.tags.map(
                              (t) => Text(
                                '#$t',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Reuse prompt',
                    onPressed: onReusePrompt,
                    icon: const Icon(Icons.content_paste_go, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Export session file',
                    onPressed: onExport,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: session.pinned ? 'Unpin' : 'Pin',
                    onPressed: onPin,
                    icon: Icon(
                      session.pinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      size: 18,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
