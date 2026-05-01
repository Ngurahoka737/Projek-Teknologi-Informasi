import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/ai_config.dart';

class AiAssistantService {
  AiAssistantService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> sendChat({
    required List<Map<String, String>> messages,
    required Map<String, dynamic> context,
  }) async {
    final response = await _postJson('/api/assistant', {
      'mode': 'chat',
      'messages': messages,
      'context': context,
    });
    return response['reply'] as String? ?? '';
  }

  Future<String> generatePlan({required Map<String, dynamic> context}) async {
    final response = await _postJson('/api/assistant', {
      'mode': 'plan',
      'context': context,
    });
    return response['reply'] as String? ?? '';
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final uri = AiConfig.endpoint(path);
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI server error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid AI response');
    }

    return decoded;
  }
}
