import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/generation_result.dart';
import '../models/generation_session.dart';
import '../models/song_idea.dart';
import '../services/history_store.dart';
import '../services/lyric_pipeline.dart';
import '../services/nanogpt_client.dart';
import '../services/prompt_eval.dart';
import '../services/secure_settings.dart';

enum AppView { idea, generating, results }

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
  })  : _client = NanoGptClient(settings: settings),
        _history = historyStore ?? HistoryStore(),
        _eval = promptEval ?? const PromptEval() {
    _pipeline = LyricPipeline(_client);
  }

  final NanoGptClient _client;
  late final LyricPipeline _pipeline;
  final HistoryStore _history;
  final PromptEval _eval;
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

  /// Active session id when viewing/editing a saved or just-generated song.
  String? currentSessionId;
  List<GenerationSession> history = [];
  bool historyLoaded = false;

  DateTime _lastStreamNotify = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> loadHistory() async {
    history = await _history.loadAll();
    historyLoaded = true;
    notifyListeners();
  }

  void updateIdea(SongIdea next) {
    idea = next;
    notifyListeners();
  }

  void _notifyStreamThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastStreamNotify).inMilliseconds >= 40) {
      _lastStreamNotify = now;
      notifyListeners();
    }
  }

  Future<void> generate() async {
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
    chat = [];
    currentSessionId = null;
    passes = LyricPipeline.initialPasses();
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
      // Final pass state
      notifyListeners();

      result = out;
      feedback = _pipeline.feedbackFor(out.lyrics);
      evalSummary = _eval.evaluateResult(out);
      view = AppView.results;
      chat = [
        ChatTurn(
          role: 'assistant',
          text: out.notes.isNotEmpty
              ? 'Ready. ${out.notes}\n\nQuality: ${evalSummary!.label}. '
                  'Copy into Suno, or ask me to refine.'
              : 'Ready. Quality: ${evalSummary!.label}. '
                  'Copy Lyrics and Style into Suno, or ask me to refine.',
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

  Future<void> sendChat(String message) async {
    final msg = message.trim();
    if (msg.isEmpty || busy || result == null) return;
    busy = true;
    error = null;
    chat = [...chat, ChatTurn(role: 'user', text: msg)];
    notifyListeners();

    final context = StringBuffer()
      ..writeln('TITLE: ${result!.title}')
      ..writeln('LYRICS:\n${result!.lyrics}')
      ..writeln('\nSTYLE:\n${result!.stylePrompt}')
      ..writeln('\nEXCLUDE:\n${result!.excludeStyles}')
      ..writeln('\nQUALITY EVAL: ${evalSummary?.label ?? 'n/a'}');

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

  void backToIdea() {
    view = AppView.idea;
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
