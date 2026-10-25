import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'secure_settings.dart';

class NanoGptException implements Exception {
  NanoGptException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'NanoGptException($statusCode): $message';
}

typedef TokenCallback = void Function(String accumulated);

/// Thin OpenAI-compatible client for NanoGPT chat completions.
class NanoGptClient {
  NanoGptClient({
    required this.settings,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final SecureSettings settings;
  final http.Client _http;

  Future<String> chat({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
    TokenCallback? onToken,
  }) async {
    if (onToken != null) {
      return chatStream(
        system: system,
        user: user,
        temperature: temperature,
        maxTokens: maxTokens,
        onToken: onToken,
      );
    }
    return _chatOnce(
      system: system,
      user: user,
      temperature: temperature,
      maxTokens: maxTokens,
      stream: false,
    );
  }

  /// SSE streaming chat completion. Calls [onToken] with the full accumulated
  /// text so far after each content delta.
  Future<String> chatStream({
    required String system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
    TokenCallback? onToken,
  }) async {
    final apiKey = await _requireApiKey();
    final baseUrl = await settings.getBaseUrl();
    final model = await settings.getModel();
    final uri = Uri.parse('$baseUrl/chat/completions');

    final body = <String, dynamic>{
      'model': model,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'temperature': temperature,
      'stream': true,
    };
    if (maxTokens != null) body['max_tokens'] = maxTokens;

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      })
      ..body = jsonEncode(body);

    final response = await _http.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errBody = await response.stream.bytesToString();
      throw NanoGptException(
        _extractError(errBody) ?? 'Request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final buffer = StringBuffer();
    var lineCarry = '';

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      lineCarry += chunk;
      final lines = lineCarry.split('\n');
      lineCarry = lines.removeLast();

      for (var line in lines) {
        line = line.trimRight();
        if (line.isEmpty) continue;
        if (line.startsWith(':')) continue; // SSE comment
        if (!line.startsWith('data:')) continue;

        var data = line.substring(5).trimLeft();
        if (data == '[DONE]') {
          onToken?.call(buffer.toString());
          return buffer.toString().trim();
        }

        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          final choices = decoded['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) continue;
          final delta = choices.first['delta'] as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            buffer.write(content);
            onToken?.call(buffer.toString());
          }
          // Some providers put full message in non-delta form mid-stream
          final message = choices.first['message'] as Map<String, dynamic>?;
          final msgContent = message?['content'] as String?;
          if (msgContent != null &&
              msgContent.isNotEmpty &&
              buffer.isEmpty) {
            buffer.write(msgContent);
            onToken?.call(buffer.toString());
          }
        } catch (_) {
          // ignore malformed SSE chunks
        }
      }
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      // Fallback: some hosts may not stream correctly
      return _chatOnce(
        system: system,
        user: user,
        temperature: temperature,
        maxTokens: maxTokens,
        stream: false,
      );
    }
    return text;
  }

  Future<String> _chatOnce({
    required String system,
    required String user,
    required double temperature,
    int? maxTokens,
    required bool stream,
  }) async {
    final apiKey = await _requireApiKey();
    final baseUrl = await settings.getBaseUrl();
    final model = await settings.getModel();
    final uri = Uri.parse('$baseUrl/chat/completions');

    final body = <String, dynamic>{
      'model': model,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'temperature': temperature,
      'stream': stream,
    };
    if (maxTokens != null) body['max_tokens'] = maxTokens;

    final response = await _http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NanoGptException(
        _extractError(response.body) ??
            'Request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw NanoGptException('Empty response from NanoGPT');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw NanoGptException('Model returned empty content');
    }
    return content.trim();
  }

  Future<String> _requireApiKey() async {
    final apiKey = await settings.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw NanoGptException(
        'API key not set. Add your NanoGPT key in Settings.',
      );
    }
    return apiKey;
  }

  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final err = decoded['error'];
        if (err is String) return err;
        if (err is Map && err['message'] != null) {
          return err['message'].toString();
        }
        if (decoded['message'] != null) return decoded['message'].toString();
      }
    } catch (_) {}
    if (body.length > 200) return '${body.substring(0, 200)}…';
    return body.isEmpty ? null : body;
  }

  void close() => _http.close();
}

/// Best-effort JSON object extraction from model output.
Map<String, dynamic> extractJsonObject(String text) {
  final trimmed = text.trim();
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}

  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start >= 0 && end > start) {
    final slice = trimmed.substring(start, end + 1);
    final decoded = jsonDecode(slice);
    if (decoded is Map<String, dynamic>) return decoded;
  }
  throw FormatException('Could not parse JSON from model output');
}
