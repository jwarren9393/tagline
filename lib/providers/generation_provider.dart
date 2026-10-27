import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'dart:convert';

import '../models/generation_result.dart';
import '../models/generation_session.dart';
import '../models/inspiration_dna.dart';
import '../models/song_idea.dart';
import '../prompts/system_prompts.dart';
import '../services/export_service.dart';
import '../services/history_store.dart';
import '../services/inspiration_dna_service.dart';
import '../services/llm_judge.dart';
import '../services/lyric_pipeline.dart';
import '../services/nanogpt_client.dart';
import '../services/prompt_eval.dart';
import '../services/secure_settings.dart';

enum AppView { idea, rescue, generating, results }

class ChatTurn {
  const ChatTurn({required this.role, required this.text});
  final String role; // user | assistant
  final String text;
}

class GenerationProvider extends ChangeNotifier {
  GenerationProvider(
    SecureSettings settings, {
    HistoryStore? historyStore,
    PromptEval? promptEval,
    ExportService? exportService,
  })  : _client = NanoGptClient(settings: settings),
        _history = historyStore ?? HistoryStore(),
        _eval = promptEval ?? const PromptEval(),
        _export = exportService ?? const ExportService() {
    _pipeline = LyricPipeline(_client);
    _judge = LlmJudge(_client);
  }

  final NanoGptClient _client;
  late final LyricPipeline _pipeline;
  late final LlmJudge _judge;
  final HistoryStore _history;
  final PromptEval _eval;
  final ExportService _export;
  final _uuid = const Uuid();

  AppView view = AppView.idea;
  SongIdea idea = const SongIdea(rawIdea: '');
  GenerationResult? result;
  List<PipelinePass> passes = LyricPipeline.initialPasses();
  LyricFeedback? feedback;
  EvalSummary? evalSummary;
  String? error;
  bool busy = false;
  List<ChatTurn> chat = [];
  String? selectedSectionTag;

  String? currentSessionId;
  List<GenerationSession> history = [];
  bool historyLoaded = false;
  List<String> sessionTags = [];
  String sunoFeedback = '';
  String llmJudgeNotes = '';
  AbComparison? abComparison;

  /// Bumped when idea is loaded into the intake form so controllers resync.
  int ideaEditToken = 0;

  String historyQuery = '';
  String? historyTagFilter;

  DateTime _lastStreamNotify = DateTime.fromMillisecondsSinceEpoch(0);

  List<GenerationSession> get filteredHistory {
    final q = historyQuery.trim().toLowerCase();
    return history.where((s) {
      if (historyTagFilter != null &&
          historyTagFilter!.isNotEmpty &&
          !s.tags.contains(historyTagFilter)) {
        return false;
      }
      if (q.isEmpty) return true;
      final hay = [
        s.displayTitle,
        s.idea.rawIdea,
        s.result.lyrics,
        s.result.stylePrompt,
        s.sunoFeedback,
        ...s.tags,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Set<String> get allHistoryTags {
    final tags = <String>{};
    for (final s in history) {
      tags.addAll(s.tags);
    }
    return tags;
  }

  Future<void> loadHistory() async {
    history = await _history.loadAll();
    historyLoaded = true;
    notifyListeners();
  }

  void setHistoryQuery(String value) {
    historyQuery = value;
    notifyListeners();
  }

  void setHistoryTagFilter(String? tag) {
    historyTagFilter = tag;
    notifyListeners();
  }

  void updateIdea(SongIdea next) {
    // Drop stale DNA when inspiration sources change.
    if (next.hasInspirationSource &&
        next.inspirationDna != null &&
        next.inspirationDna!.sourceFingerprint != next.inspirationFingerprint) {
      idea = next.copyWith(clearInspirationDna: true);
    } else if (!next.hasInspirationSource && next.inspirationDna != null) {
      idea = next.copyWith(clearInspirationDna: true);
    } else {
      idea = next;
    }
    notifyListeners();
  }

  /// Extract abstract inspiration DNA without running the full lyric pipeline.
  Future<void> extractInspirationDna() async {
    if (!idea.hasInspirationSource) {
      error =
          'Add an artist, song title, and/or a short lyrics excerpt for inspiration.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final dna = await _pipeline.extractInspirationDna(
        artist: idea.inspirationArtist,
        song: idea.inspirationSong,
        lyricsExcerpt: idea.inspirationLyricsExcerpt,
      );
      idea = idea.copyWith(inspirationDna: dna);
    } on InspirationDnaException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _notifyStreamThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastStreamNotify).inMilliseconds >= 40) {
      _lastStreamNotify = now;
      notifyListeners();
    }
  }

  void showGenerateMode() {
    error = null;
    idea = idea.copyWith(mode: 'generate');
    view = AppView.idea;
    ideaEditToken++;
    notifyListeners();
  }

  void showRescueMode() {
    error = null;
    idea = idea.copyWith(
      mode: 'rescue',
      rescue: idea.rescue,
    );
    view = AppView.rescue;
    ideaEditToken++;
    notifyListeners();
  }

  Future<void> generate({bool createNewSession = true}) async {
    if (idea.isRescue) {
      await rescueLyrics(createNewSession: createNewSession);
      return;
    }
    if (!idea.isValid) {
      error = 'Enter a song idea (at least a short sentence).';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    result = null;
    feedback = null;
    evalSummary = null;
    llmJudgeNotes = '';
    abComparison = null;
    chat = [];
    if (createNewSession) {
      currentSessionId = null;
      sessionTags = [];
      // keep sunoFeedback only if regenerating same session — cleared for new
      sunoFeedback = '';
    }
    passes = LyricPipeline.initialPasses(
      withInspiration: idea.hasInspirationSource,
    );
    view = AppView.generating;
    notifyListeners();

    try {
      final out = await _pipeline.generate(
        idea: idea,
        onProgress: (p) {
          passes = p;
          _notifyStreamThrottled();
        },
      );
      notifyListeners();

      final inspRaw = out.passArtifacts['inspiration'];
      if (inspRaw != null && inspRaw.trim().isNotEmpty) {
        try {
          final dna = InspirationDna.fromJson(
            Map<String, dynamic>.from(jsonDecode(inspRaw) as Map),
          );
          idea = idea.copyWith(inspirationDna: dna);
        } catch (_) {
          // Keep prior idea DNA if parse fails.
        }
      }

      result = out;
      feedback = _pipeline.feedbackFor(out.lyrics);
      evalSummary = _eval.evaluateResult(out);
      view = AppView.results;
      chat = [
        ChatTurn(
          role: 'assistant',
          text: out.notes.isNotEmpty
              ? 'Ready. ${out.notes}\n\nQuality: ${evalSummary!.label}. '
                  'Your original prompt is at the top — edit & regenerate anytime.'
              : 'Ready. Quality: ${evalSummary!.label}. '
                  'Your original prompt is at the top — edit & regenerate anytime.',
        ),
      ];
      await _persistCurrent(createIfNeeded: true);
    } catch (e) {
      error = e.toString();
      view = AppView.idea;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Regenerate using the (possibly edited) idea while keeping the session.
  Future<void> regenerateFromPrompt() => generate(createNewSession: false);

  /// Remaster pasted Suno lyrics with Tagline craft (diagnose → rewrite → polish).
  Future<void> rescueLyrics({bool createNewSession = true}) async {
    final rescue = idea.rescue;
    if (rescue == null || !rescue.isValid) {
      error = 'Paste the original lyrics (at least a short verse/chorus block).';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    result = null;
    feedback = null;
    evalSummary = null;
    llmJudgeNotes = '';
    abComparison = null;
    chat = [];
    idea = idea.copyWith(mode: 'rescue', rescue: rescue);
    if (createNewSession) {
      currentSessionId = null;
      sessionTags = ['rescue'];
      sunoFeedback = '';
    } else if (!sessionTags.contains('rescue')) {
      sessionTags = [...sessionTags, 'rescue'];
    }
    passes = LyricPipeline.initialRescuePasses();
    view = AppView.generating;
    notifyListeners();

    try {
      final out = await _pipeline.rescue(
        input: rescue,
        onProgress: (p) {
          passes = p;
          _notifyStreamThrottled();
        },
      );
      notifyListeners();
      result = out;
      feedback = _pipeline.feedbackFor(out.lyrics);
      evalSummary = _eval.evaluateResult(out);
      view = AppView.results;
      chat = [
        ChatTurn(
          role: 'assistant',
          text: out.notes.isNotEmpty
              ? 'Rescue ready. ${out.notes}\n\nQuality: ${evalSummary!.label}. '
                  'Copy the pack back into Suno for a remix, cover, or reuse.'
              : 'Rescue ready. Quality: ${evalSummary!.label}. '
                  'Copy the pack back into Suno for a remix, cover, or reuse.',
        ),
      ];
      await _persistCurrent(createIfNeeded: true);
    } catch (e) {
      error = e.toString();
      view = AppView.rescue;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> runAbExperiment() async {
    if (result == null || busy) return;
    final scenes = result!.passArtifacts['scenes'];
    final arc = result!.passArtifacts['arc'];
    if (scenes == null ||
        scenes.isEmpty ||
        arc == null ||
        arc.isEmpty) {
      error =
          'A/B needs scene/arc artifacts from a full generate. Run Generate once first.';
      notifyListeners();
      return;
    }

    busy = true;
    error = null;
    view = AppView.generating;
    passes = [
      const PipelinePass(
        id: 'ab_info',
        label: 'A/B setup',
        description: 'Reusing scene/arc; drafting variants A and B',
        status: PassStatus.done,
        output: 'Variant A = standard craft · Variant B = voice + section turns',
      ),
    ];
    notifyListeners();

    try {
      // Variant A
      final a = await _pipeline.generateLyricBranch(
        idea: idea,
        scenesJson: scenes,
        arcJson: arc,
        draftSystem: SystemPrompts.draftLyricsSystem(),
        branchLabel: 'A',
        onProgress: (p) {
          passes = [
            passes.first,
            ...p,
          ];
          _notifyStreamThrottled();
        },
      );
      final evalA = _eval.evaluate(
        lyrics: a.lyrics,
        style: result!.stylePrompt,
        exclude: result!.excludeStyles,
      );

      // Variant B
      final b = await _pipeline.generateLyricBranch(
        idea: idea,
        scenesJson: scenes,
        arcJson: arc,
        draftSystem: SystemPrompts.draftLyricsSystemVariantB(),
        branchLabel: 'B',
        onProgress: (p) {
          passes = [
            passes.first,
            ...p,
          ];
          _notifyStreamThrottled();
        },
      );
      final evalB = _eval.evaluate(
        lyrics: b.lyrics,
        style: result!.stylePrompt,
        exclude: result!.excludeStyles,
      );

      final pickB = evalB.score > evalA.score;
      final winner = pickB ? b : a;
      final winnerEval = pickB ? evalB : evalA;
      abComparison = AbComparison(
        winner: pickB ? 'B' : 'A',
        scoreA: evalA.score,
        scoreB: evalB.score,
        maxScore: evalA.maxScore,
        notes: pickB
            ? 'Kept voice/substance variant B.'
            : 'Kept standard craft variant A.',
      );

      result = result!.copyWith(
        lyrics: winner.lyrics,
        title: winner.title.isNotEmpty ? winner.title : result!.title,
        notes: winner.notes,
        passArtifacts: {
          ...result!.passArtifacts,
          'ab_a': a.lyrics,
          'ab_b': b.lyrics,
        },
      );
      evalSummary = winnerEval;
      feedback = _pipeline.feedbackFor(winner.lyrics);
      view = AppView.results;
      chat = [
        ...chat,
        ChatTurn(
          role: 'assistant',
          text:
              'A/B done. A ${evalA.score}/${evalA.maxScore} vs '
              'B ${evalB.score}/${evalB.maxScore} → kept ${abComparison!.winner}. '
              '${abComparison!.notes}',
        ),
      ];
      await _persistCurrent();
    } catch (e) {
      error = e.toString();
      view = AppView.results;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> runLlmJudge() async {
    if (result == null || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final judged = await _judge.judge(
        result: result!,
        localEvalLabel: evalSummary?.label ?? 'n/a',
      );
      llmJudgeNotes = judged.toDisplayNotes();
      chat = [
        ...chat,
        ChatTurn(role: 'assistant', text: llmJudgeNotes),
      ];
      await _persistCurrent();
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> makeMoreSpecific() async {
    if (result == null || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final lyrics = await _pipeline.makeMoreSpecific(
        result!.lyrics,
        onToken: (acc) {
          result = result!.copyWith(lyrics: acc);
          _notifyStreamThrottled();
        },
      );
      result = result!.copyWith(lyrics: lyrics);
      feedback = _pipeline.feedbackFor(lyrics);
      evalSummary = _eval.evaluateResult(result!);
      chat = [
        ...chat,
        ChatTurn(
          role: 'assistant',
          text: 'Made lyrics more specific. ${evalSummary!.label}.',
        ),
      ];
      await _persistCurrent();
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> regenerateSelectedSection() async {
    if (result == null || busy) return;
    final tag = selectedSectionTag;
    if (tag == null || tag.isEmpty) {
      error = 'Select a section tag to regenerate.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final lyrics = await _pipeline.regenerateSection(
        lyrics: result!.lyrics,
        sectionTag: tag,
        onToken: (acc) {
          result = result!.copyWith(lyrics: acc);
          _notifyStreamThrottled();
        },
      );
      result = result!.copyWith(lyrics: lyrics);
      feedback = _pipeline.feedbackFor(lyrics);
      evalSummary = _eval.evaluateResult(result!);
      chat = [
        ...chat,
        ChatTurn(
          role: 'assistant',
          text: 'Regenerated $tag. ${evalSummary!.label}.',
        ),
      ];
      await _persistCurrent();
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void setLyricsLocally(String lyrics) {
    if (result == null) return;
    result = result!.copyWith(lyrics: lyrics);
    feedback = _pipeline.feedbackFor(lyrics);
    notifyListeners();
  }

  void setStyleLocally(String style) {
    if (result == null) return;
    result = result!.copyWith(stylePrompt: style);
    notifyListeners();
  }

  void setExcludeLocally(String exclude) {
    if (result == null) return;
    result = result!.copyWith(excludeStyles: exclude);
    notifyListeners();
  }

  void setSunoFeedback(String value) {
    sunoFeedback = value;
    notifyListeners();
  }

  void setSessionTags(List<String> tags) {
    sessionTags = tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    notifyListeners();
    if (result != null) {
      _persistCurrent(createIfNeeded: true);
    }
  }

  Future<void> saveEdits() async {
    if (result == null) return;
    evalSummary = _eval.evaluateResult(result!);
    await _persistCurrent(createIfNeeded: true);
    notifyListeners();
  }

  void reevaluate() {
    if (result == null) return;
    evalSummary = _eval.evaluateResult(result!);
    feedback = _pipeline.feedbackFor(result!.lyrics);
    notifyListeners();
  }

  Future<void> copyExportPack() async {
    if (result == null) return;
    final pack = _export.buildPack(idea: idea, result: result!);
    await Clipboard.setData(ClipboardData(text: pack));
  }

  /// Share Suno pack. Does not set [busy] so the UI stays responsive.
  Future<ShareOutcome> shareExportPack({Rect? sharePositionOrigin}) async {
    if (result == null) {
      throw const ExportException('Nothing to share yet.');
    }
    return _export.sharePack(
      idea: idea,
      result: result!,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  GenerationSession? get currentSessionSnapshot {
    if (result == null || currentSessionId == null) return null;
    GenerationSession? existing;
    for (final s in history) {
      if (s.id == currentSessionId) {
        existing = s;
        break;
      }
    }
    final now = DateTime.now().toUtc();
    return GenerationSession(
      id: currentSessionId!,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      idea: idea,
      result: result!,
      evalSummary: evalSummary,
      pinned: existing?.pinned ?? false,
      tags: sessionTags,
      sunoFeedback: sunoFeedback,
      llmJudgeNotes: llmJudgeNotes,
      abComparison: abComparison,
    );
  }

  Future<ShareOutcome> exportCurrentSession({
    Rect? sharePositionOrigin,
  }) async {
    await saveEdits();
    final session = currentSessionSnapshot;
    if (session == null) {
      throw const ExportException('Save a generation before exporting.');
    }
    return _export.exportSessionFile(
      session,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<ShareOutcome> exportSession(
    GenerationSession session, {
    Rect? sharePositionOrigin,
  }) {
    return _export.exportSessionFile(
      session,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<ShareOutcome> exportFullHistory({Rect? sharePositionOrigin}) async {
    await loadHistory();
    if (history.isEmpty) {
      throw const ExportException('History is empty.');
    }
    return _export.exportHistoryFile(
      history,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Import session/history file(s) into local history (upsert by id).
  Future<int> importSessionsFromFile() async {
    final imported = await _export.pickAndParseImport();
    if (imported.isEmpty) return 0;
    history = await _history.upsertAll(imported);
    historyLoaded = true;
    notifyListeners();
    return imported.length;
  }

  Future<void> sendChat(String message) async {
    final msg = message.trim();
    if (msg.isEmpty || busy || result == null) return;
    busy = true;
    error = null;
    chat = [...chat, ChatTurn(role: 'user', text: msg)];
    notifyListeners();

    final context = StringBuffer()
      ..writeln('TITLE: ${result!.title}')
      ..writeln('ORIGINAL PROMPT:\n${idea.rawIdea}')
      ..writeln('LYRICS:\n${result!.lyrics}')
      ..writeln('\nSTYLE:\n${result!.stylePrompt}')
      ..writeln('\nEXCLUDE:\n${result!.excludeStyles}')
      ..writeln('\nQUALITY EVAL: ${evalSummary?.label ?? 'n/a'}');
    if (sunoFeedback.trim().isNotEmpty) {
      context.writeln('\nSUNO FEEDBACK (user notes after generating in Suno):');
      context.writeln(sunoFeedback.trim());
    }
    if (llmJudgeNotes.trim().isNotEmpty) {
      context.writeln('\nLLM JUDGE:\n$llmJudgeNotes');
    }

    try {
      chat = [...chat, const ChatTurn(role: 'assistant', text: '')];
      final reply = await _pipeline.refineChat(
        historyContext: context.toString(),
        userMessage: msg,
        onToken: (acc) {
          chat = [
            ...chat.sublist(0, chat.length - 1),
            ChatTurn(role: 'assistant', text: acc),
          ];
          _notifyStreamThrottled();
        },
      );
      chat = [
        ...chat.sublist(0, chat.length - 1),
        ChatTurn(role: 'assistant', text: reply),
      ];
    } catch (e) {
      error = e.toString();
      if (chat.isNotEmpty &&
          chat.last.role == 'assistant' &&
          chat.last.text.isEmpty) {
        chat = chat.sublist(0, chat.length - 1);
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void backToIdea({bool clearResult = false}) {
    if (clearResult) {
      result = null;
      currentSessionId = null;
    }
    view = idea.isRescue ? AppView.rescue : AppView.idea;
    ideaEditToken++;
    notifyListeners();
  }

  /// Load current idea into intake for a fresh generation (keeps text).
  void usePromptAsNewIdea() {
    result = null;
    currentSessionId = null;
    sessionTags = List<String>.from(sessionTags);
    sunoFeedback = '';
    llmJudgeNotes = '';
    abComparison = null;
    view = idea.isRescue ? AppView.rescue : AppView.idea;
    ideaEditToken++;
    notifyListeners();
  }

  void selectSection(String? tag) {
    selectedSectionTag = tag;
    notifyListeners();
  }

  Future<void> openSession(GenerationSession session) async {
    currentSessionId = session.id;
    idea = session.idea;
    result = session.result;
    evalSummary = session.evalSummary ?? _eval.evaluateResult(session.result);
    feedback = _pipeline.feedbackFor(session.result.lyrics);
    sessionTags = List<String>.from(session.tags);
    sunoFeedback = session.sunoFeedback;
    llmJudgeNotes = session.llmJudgeNotes;
    abComparison = session.abComparison;
    chat = [
      ChatTurn(
        role: 'assistant',
        text:
            'Restored “${session.displayTitle}”. Quality: ${evalSummary!.label}.',
      ),
    ];
    view = AppView.results;
    notifyListeners();
  }

  /// Open only the prompt into intake (reuse / tweak for a new run).
  void reusePromptFromSession(GenerationSession session) {
    idea = session.idea;
    result = null;
    currentSessionId = null;
    sessionTags = List<String>.from(session.tags);
    sunoFeedback = '';
    llmJudgeNotes = '';
    abComparison = null;
    view = idea.isRescue ? AppView.rescue : AppView.idea;
    ideaEditToken++;
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    history = await _history.delete(id);
    if (currentSessionId == id) {
      currentSessionId = null;
    }
    notifyListeners();
  }

  Future<void> togglePin(GenerationSession session) async {
    final updated = session.copyWith(
      pinned: !session.pinned,
      updatedAt: DateTime.now().toUtc(),
    );
    history = await _history.upsert(updated);
    notifyListeners();
  }

  Future<void> _persistCurrent({bool createIfNeeded = false}) async {
    if (result == null) return;
    final now = DateTime.now().toUtc();
    if (currentSessionId == null) {
      if (!createIfNeeded) return;
      currentSessionId = _uuid.v4();
      final session = GenerationSession(
        id: currentSessionId!,
        createdAt: now,
        updatedAt: now,
        idea: idea,
        result: result!,
        evalSummary: evalSummary,
        tags: sessionTags,
        sunoFeedback: sunoFeedback,
        llmJudgeNotes: llmJudgeNotes,
        abComparison: abComparison,
      );
      history = await _history.upsert(session);
      return;
    }
    GenerationSession? existing;
    for (final s in history) {
      if (s.id == currentSessionId) {
        existing = s;
        break;
      }
    }
    final session = GenerationSession(
      id: currentSessionId!,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      idea: idea,
      result: result!,
      evalSummary: evalSummary,
      pinned: existing?.pinned ?? false,
      tags: sessionTags,
      sunoFeedback: sunoFeedback,
      llmJudgeNotes: llmJudgeNotes,
      abComparison: abComparison,
    );
    history = await _history.upsert(session);
  }

  List<String> get sectionTags {
    final lyrics = result?.lyrics ?? '';
    final re = RegExp(r'^\s*(\[.+?\])\s*$', multiLine: true);
    return re.allMatches(lyrics).map((m) => m.group(1)!).toSet().toList();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
