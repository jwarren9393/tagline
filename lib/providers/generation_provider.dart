import 'package:flutter/foundation.dart';

import '../models/generation_result.dart';
import '../models/song_idea.dart';
import '../services/lyric_pipeline.dart';
import '../services/nanogpt_client.dart';
import '../services/secure_settings.dart';

enum AppView { idea, generating, results }

class ChatTurn {
  const ChatTurn({required this.role, required this.text});
  final String role; // user | assistant
  final String text;
}

class GenerationProvider extends ChangeNotifier {
  GenerationProvider(SecureSettings settings)
      : _client = NanoGptClient(settings: settings) {
    _pipeline = LyricPipeline(_client);
  }

  final NanoGptClient _client;
  late final LyricPipeline _pipeline;

  AppView view = AppView.idea;
  SongIdea idea = const SongIdea(rawIdea: '');
  GenerationResult? result;
  List<PipelinePass> passes = LyricPipeline.initialPasses();
  LyricFeedback? feedback;
  String? error;
  bool busy = false;
  List<ChatTurn> chat = [];
  String? selectedSectionTag;

  void updateIdea(SongIdea next) {
    idea = next;
    notifyListeners();
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
    chat = [];
    passes = LyricPipeline.initialPasses();
    view = AppView.generating;
    notifyListeners();

    try {
      final out = await _pipeline.generate(
        idea: idea,
        onProgress: (p) {
          passes = p;
          notifyListeners();
        },
      );
      result = out;
      feedback = _pipeline.feedbackFor(out.lyrics);
      view = AppView.results;
      chat = [
        ChatTurn(
          role: 'assistant',
          text: out.notes.isNotEmpty
              ? 'Ready. ${out.notes}\n\nUse the panels to copy into Suno, or ask me to refine.'
              : 'Ready. Copy Lyrics and Style into Suno Custom Mode / Studio, or ask me to refine.',
        ),
      ];
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
      final lyrics = await _pipeline.makeMoreSpecific(result!.lyrics);
      result = result!.copyWith(lyrics: lyrics);
      feedback = _pipeline.feedbackFor(lyrics);
      chat = [
        ...chat,
        const ChatTurn(role: 'assistant', text: 'Made lyrics more specific.'),
      ];
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
      );
      result = result!.copyWith(lyrics: lyrics);
      feedback = _pipeline.feedbackFor(lyrics);
      chat = [
        ...chat,
        ChatTurn(role: 'assistant', text: 'Regenerated $tag.'),
      ];
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
      ..writeln('\nEXCLUDE:\n${result!.excludeStyles}');

    try {
      final reply = await _pipeline.refineChat(
        historyContext: context.toString(),
        userMessage: msg,
      );
      chat = [...chat, ChatTurn(role: 'assistant', text: reply)];
    } catch (e) {
      error = e.toString();
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

  List<String> get sectionTags {
    final lyrics = result?.lyrics ?? '';
    final re = RegExp(r'^\s*(\[.+?\])\s*$', multiLine: true);
    return re
        .allMatches(lyrics)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
