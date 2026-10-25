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
  }) async {
    final apiKey = await settings.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw NanoGptException(
        'API key not set. Add your NanoGPT key in Settings.',
      );
    }

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
      'stream': false,
    };
    if (maxTokens != null) {
      body['max_tokens'] = maxTokens;
    }

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
