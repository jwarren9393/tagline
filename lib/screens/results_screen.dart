import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/generation_session.dart';
import '../models/lyric_rescue_input.dart';
import '../providers/generation_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/eval_panel.dart';
import '../widgets/feedback_panel.dart';
import '../widgets/output_panel.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _chatController = TextEditingController();
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gen = context.watch<GenerationProvider>();
    final result = gen.result;
    if (result == null) {
      return const Center(child: Text('No result'));
    }

    final wide = MediaQuery.sizeOf(context).width >= 1000;

    final tools = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: gen.busy ? null : () => gen.makeMoreSpecific(),
          icon: const Icon(Icons.center_focus_strong, size: 18),
          label: const Text('More specific'),
        ),
        DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              hint: const Text('Section…'),
              value: gen.sectionTags.contains(gen.selectedSectionTag)
                  ? gen.selectedSectionTag
                  : null,
              items: gen.sectionTags
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: gen.selectSection,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: gen.busy ? null : () => gen.regenerateSelectedSection(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Regen section'),
        ),
        OutlinedButton.icon(
          onPressed: gen.busy
              ? null
              : () async {
                  await gen.saveEdits();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to history')),
                    );
                  }
                },
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save'),
        ),
        OutlinedButton.icon(
          onPressed: gen.busy
              ? null
              : () async {
                  await gen.copyExportPack();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Full Suno pack copied')),
                    );
                  }
                },
          icon: const Icon(Icons.copy_all_outlined, size: 18),
          label: const Text('Copy pack'),
        ),
        Builder(
          builder: (btnContext) => OutlinedButton.icon(
            onPressed: gen.busy
                ? null
                : () async {
                    try {
                      final outcome = await gen.shareExportPack(
                        sharePositionOrigin:
                            shareOriginFromContext(btnContext),
                      );
                      if (!btnContext.mounted || outcome.isCancelled) return;
                      ScaffoldMessenger.of(btnContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            outcome.kind == ShareOutcomeKind.saved
                                ? 'Saved pack to ${outcome.path}'
                                : 'Share sheet opened',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!btnContext.mounted) return;
                      ScaffoldMessenger.of(btnContext).showSnackBar(
                        SnackBar(
                          content: Text('$e'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Share'),
          ),
        ),
        Builder(
          builder: (btnContext) => OutlinedButton.icon(
            onPressed: gen.busy
                ? null
                : () async {
                    try {
                      final outcome = await gen.exportCurrentSession(
                        sharePositionOrigin:
                            shareOriginFromContext(btnContext),
                      );
                      if (!btnContext.mounted || outcome.isCancelled) return;
                      ScaffoldMessenger.of(btnContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            outcome.kind == ShareOutcomeKind.saved
                                ? 'Session exported to ${outcome.path}'
                                : 'Session file ready to send',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!btnContext.mounted) return;
                      ScaffoldMessenger.of(btnContext).showSnackBar(
                        SnackBar(
                          content: Text('$e'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('Export session'),
          ),
        ),
        OutlinedButton.icon(
          onPressed: gen.busy ? null : () => gen.runLlmJudge(),
          icon: const Icon(Icons.gavel_outlined, size: 18),
          label: const Text('LLM judge'),
        ),
        OutlinedButton.icon(
          onPressed: gen.busy ? null : () => gen.runAbExperiment(),
          icon: const Icon(Icons.compare_arrows, size: 18),
          label: const Text('A/B test'),
        ),
        if (gen.busy)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );

    final isRescue = gen.idea.isRescue;
    final promptPanel = OutputPanel(
      key: ValueKey('prompt-${gen.currentSessionId}-${gen.ideaEditToken}'),
      title: isRescue ? 'Rescue intent' : 'Your prompt',
      subtitle: isRescue
          ? 'Your notes behind the original song — edit, then re-rescue'
          : 'Original Tagline idea — edit, then regenerate or start new',
      text: isRescue
          ? (gen.idea.rescue?.creatorNotes.trim().isNotEmpty == true
              ? gen.idea.rescue!.creatorNotes
              : gen.idea.rawIdea)
          : gen.idea.rawIdea,
      editable: true,
      minLines: 3,
      maxLines: null,
      onChanged: (v) {
        if (isRescue) {
          final r = gen.idea.rescue;
          gen.updateIdea(
            gen.idea.copyWith(
              rawIdea: v,
              rescue: r?.copyWith(creatorNotes: v) ??
                  LyricRescueInput(creatorNotes: v, lyrics: ''),
            ),
          );
        } else {
          gen.updateIdea(gen.idea.copyWith(rawIdea: v));
        }
      },
      footer: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: gen.busy ? null : () => gen.regenerateFromPrompt(),
            icon: Icon(
              isRescue ? Icons.healing_outlined : Icons.auto_awesome,
              size: 18,
            ),
            label: Text(
              isRescue
                  ? 'Re-rescue from this paste'
                  : 'Regenerate from this prompt',
            ),
          ),
          OutlinedButton.icon(
            onPressed: gen.busy ? null : () => gen.usePromptAsNewIdea(),
            icon: const Icon(Icons.edit_note, size: 18),
            label: Text(isRescue ? 'Edit rescue paste' : 'Edit as new idea'),
          ),
        ],
      ),
    );

    final lyricsPanel = OutputPanel(
      key: ValueKey('lyrics-${gen.currentSessionId}'),
      title: result.title.isEmpty ? 'Lyrics' : result.title,
      subtitle: 'Paste into Suno Lyrics · structure tags on their own lines',
      text: result.lyrics,
      editable: true,
      minLines: 8,
      maxLines: null,
      onChanged: gen.setLyricsLocally,
      footer: tools,
    );

    final lowerPanels = Column(
      children: [
        OutputPanel(
          key: ValueKey('style-${gen.currentSessionId}'),
          title: 'Style',
          subtitle: 'Sound only · front-loaded · no story / no tags',
          text: result.stylePrompt,
          editable: true,
          minLines: 3,
          maxLines: null,
          onChanged: gen.setStyleLocally,
        ),
        const SizedBox(height: 12),
        OutputPanel(
          key: ValueKey('exclude-${gen.currentSessionId}'),
          title: 'Exclude Styles',
          subtitle: 'Negatives live here — not inline in Style',
          text: result.excludeStyles,
          editable: true,
          minLines: 2,
          maxLines: null,
          onChanged: gen.setExcludeLocally,
        ),
        const SizedBox(height: 12),
        _TagsPanel(gen: gen, tagController: _tagController),
        const SizedBox(height: 12),
        _SunoFeedbackPanel(gen: gen),
        if (gen.abComparison != null) ...[
          const SizedBox(height: 12),
          _AbBanner(comparison: gen.abComparison!),
        ],
        if (gen.evalSummary != null) ...[
          const SizedBox(height: 12),
          EvalPanel(
            summary: gen.evalSummary!,
            onReevaluate: gen.reevaluate,
          ),
        ],
        if (gen.llmJudgeNotes.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutputPanel(
            title: 'LLM judge',
            subtitle: 'Second opinion vs the same craft rubric',
            text: gen.llmJudgeNotes,
            editable: false,
            minLines: 3,
          ),
        ],
        if (gen.feedback != null) ...[
          const SizedBox(height: 12),
          FeedbackPanel(feedback: gen.feedback!),
        ],
        const SizedBox(height: 12),
        _RefinementChat(controller: _chatController, gen: gen),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => gen.backToIdea(),
                icon: const Icon(Icons.arrow_back),
                label: Text(gen.idea.isRescue ? 'Rescue' : 'Idea'),
              ),
              TextButton(
                onPressed: gen.usePromptAsNewIdea,
                child: Text(
                  gen.idea.isRescue ? 'Edit paste' : 'New from prompt',
                ),
              ),
              const Spacer(),
              if (gen.error != null)
                Flexible(
                  child: Text(
                    gen.error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 28),
                        child: Column(
                          children: [
                            promptPanel,
                            const SizedBox(height: 12),
                            lyricsPanel,
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(8, 8, 16, 28),
                        child: lowerPanels,
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    children: [
                      promptPanel,
                      const SizedBox(height: 12),
                      lyricsPanel,
                      const SizedBox(height: 12),
                      lowerPanels,
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _TagsPanel extends StatelessWidget {
  const _TagsPanel({required this.gen, required this.tagController});

  final GenerationProvider gen;
  final TextEditingController tagController;

  @override
  Widget build(BuildContext context) {
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
          Text('Tags', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Organize history (e.g. breakup, demo, client).',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...gen.sessionTags.map(
                (t) => InputChip(
                  label: Text(t),
                  onDeleted: () {
                    final next = List<String>.from(gen.sessionTags)..remove(t);
                    gen.setSessionTags(next);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: tagController,
                  decoration: const InputDecoration(
                    hintText: 'Add tag',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              IconButton(
                onPressed: _add,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _add() {
    final t = tagController.text.trim();
    if (t.isEmpty) return;
    gen.setSessionTags([...gen.sessionTags, t]);
    tagController.clear();
  }
}

class _SunoFeedbackPanel extends StatefulWidget {
  const _SunoFeedbackPanel({required this.gen});
  final GenerationProvider gen;

  @override
  State<_SunoFeedbackPanel> createState() => _SunoFeedbackPanelState();
}

class _SunoFeedbackPanelState extends State<_SunoFeedbackPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.gen.sunoFeedback);
  }

  @override
  void didUpdateWidget(covariant _SunoFeedbackPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gen.sunoFeedback != _controller.text &&
        widget.gen.currentSessionId != oldWidget.gen.currentSessionId) {
      _controller.text = widget.gen.sunoFeedback;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Suno feedback loop',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'After you generate in Suno: what rushed, mushy, or worked? '
            'Saved with the session and fed into Refine.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: null,
            onChanged: widget.gen.setSunoFeedback,
            decoration: const InputDecoration(
              hintText: 'e.g. Verse 2 rushed; chorus landed; bridge too wordy',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.gen.busy
                  ? null
                  : () async {
                      await widget.gen.saveEdits();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Feedback saved')),
                        );
                      }
                    },
              child: const Text('Save feedback'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AbBanner extends StatelessWidget {
  const _AbBanner({required this.comparison});
  final AbComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inkElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
      ),
      child: Text(
        'A/B: kept ${comparison.winner} '
        '(A ${comparison.scoreA}/${comparison.maxScore} · '
        'B ${comparison.scoreB}/${comparison.maxScore}). ${comparison.notes}',
        style: const TextStyle(height: 1.35),
      ),
    );
  }
}

class _RefinementChat extends StatelessWidget {
  const _RefinementChat({
    required this.controller,
    required this.gen,
  });

  final TextEditingController controller;
  final GenerationProvider gen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inkElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Refine',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final turn in gen.chat)
                  Align(
                    alignment: turn.role == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      constraints: const BoxConstraints(maxWidth: 420),
                      decoration: BoxDecoration(
                        color: turn.role == 'user'
                            ? AppColors.amber.withValues(alpha: 0.15)
                            : AppColors.inkSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        turn.text,
                        style: const TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ask to tighten the chorus, swap an image…',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: gen.busy ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = controller.text;
    controller.clear();
    gen.sendChat(text);
  }
}
