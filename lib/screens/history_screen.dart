import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/generation_session.dart';
import '../providers/generation_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GenerationProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gen = context.watch<GenerationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: !gen.historyLoaded
          ? const Center(child: CircularProgressIndicator())
          : gen.history.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No saved generations yet.\n'
                      'Successful runs are saved automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, height: 1.4),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: gen.history.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final session = gen.history[index];
                    return _HistoryTile(
                      session: session,
                      onOpen: () {
                        gen.openSession(session);
                        Navigator.of(context).pop();
                      },
                      onPin: () => gen.togglePin(session),
                      onDelete: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete generation?'),
                            content: Text('Remove “${session.displayTitle}”?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
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
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.session,
    required this.onOpen,
    required this.onPin,
    required this.onDelete,
  });

  final GenerationSession session;
  final VoidCallback onOpen;
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
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                session.pinned ? Icons.push_pin : Icons.music_note_outlined,
                color: session.pinned ? AppColors.amber : AppColors.textMuted,
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
                      session.preview.isEmpty
                          ? session.idea.rawIdea.trim()
                          : session.preview,
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
                      ],
                    ),
                  ],
                ),
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
