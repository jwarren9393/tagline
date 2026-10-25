import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/generation_provider.dart';
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

  @override
  void dispose() {
    _chatController.dispose();
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
          label: const Text('Make more specific'),
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
                  .map(
                    (t) => DropdownMenuItem(value: t, child: Text(t)),
                  )
                  .toList(),
              onChanged: gen.selectSection,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: gen.busy ? null : () => gen.regenerateSelectedSection(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Regenerate section'),
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

    final lyricsPanel = OutputPanel(
      title: result.title.isEmpty ? 'Lyrics' : result.title,
      subtitle: 'Paste into Suno Lyrics · structure tags on their own lines',
      text: result.lyrics,
      editable: true,
      minLines: 16,
      maxLines: 28,
      onChanged: gen.setLyricsLocally,
      footer: tools,
    );

    final styleColumn = Column(
      children: [
        OutputPanel(
          title: 'Style',
          subtitle: 'Sound only · front-loaded · no story / no tags',
          text: result.stylePrompt,
          editable: true,
          minLines: 5,
          maxLines: 10,
          onChanged: gen.setStyleLocally,
        ),
        const SizedBox(height: 12),
        OutputPanel(
          title: 'Exclude Styles',
          subtitle: 'Negatives live here — not inline in Style',
          text: result.excludeStyles,
          editable: true,
          minLines: 3,
          maxLines: 6,
          onChanged: gen.setExcludeLocally,
        ),
        if (gen.evalSummary != null) ...[
          const SizedBox(height: 12),
          EvalPanel(
            summary: gen.evalSummary!,
            onReevaluate: gen.reevaluate,
          ),
        ],
        if (gen.feedback != null) ...[
          const SizedBox(height: 12),
          FeedbackPanel(feedback: gen.feedback!),
        ],
        const SizedBox(height: 12),
        _RefinementChat(
          controller: _chatController,
          gen: gen,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: gen.backToIdea,
                icon: const Icon(Icons.arrow_back),
                label: const Text('New idea'),
              ),
              const Spacer(),
              if (gen.error != null)
                Flexible(
                  child: Text(
                    gen.error!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: SingleChildScrollView(child: lyricsPanel)),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: SingleChildScrollView(child: styleColumn)),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        lyricsPanel,
                        const SizedBox(height: 16),
                        styleColumn,
                      ],
                    ),
                  ),
          ),
        ],
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
          SizedBox(
            height: 180,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: gen.chat.length,
              itemBuilder: (context, i) {
                final turn = gen.chat[i];
                final isUser = turn.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.amber.withValues(alpha: 0.15)
                          : AppColors.inkSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      turn.text,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                );
              },
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
                    maxLines: 3,
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
