// lib/services/sarvam_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fera_ai_assistant/models/chat_message.dart';
import 'package:fera_ai_assistant/utils/constants.dart';

/// Thin HTTP client for the Sarvam-1 (2B parameter) Indic language model.
///
/// The API is modelled after the OpenAI chat-completions interface.
/// Replace [AppConstants.sarvamChatEndpoint] and auth headers once you have
/// your Sarvam API credentials.
class SarvamApiService {
  SarvamApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ---------------------------------------------------------------------------
  // Chat / completions
  // ---------------------------------------------------------------------------

  /// Sends [messages] to Sarvam-1 and returns the assistant reply text.
  ///
  /// [systemPrompt] is injected as the first system message.
  /// [locale] is passed as a hint so the model responds in the correct language.
  Future<String> chat({
    required List<ChatMessage> messages,
    required String locale,
    String? systemPrompt,
  }) async {
    final payload = _buildPayload(
      messages: messages,
      locale: locale,
      systemPrompt: systemPrompt,
    );

    final response = await _client
        .post(
          Uri.parse(AppConstants.sarvamChatEndpoint),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(AppConstants.receiveTimeout);

    if (response.statusCode != 200) {
      throw SarvamApiException(
        statusCode: response.statusCode,
        message: 'Chat API error: ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _extractContent(body);
  }

  // ---------------------------------------------------------------------------
  // Speech-to-Text (Sarvam hosted)
  // ---------------------------------------------------------------------------

  /// Transcribes [audioBytes] (WAV/FLAC) using Sarvam's STT API.
  /// Returns the transcribed text.
  Future<String> transcribeAudio({
    required List<int> audioBytes,
    required String locale,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConstants.sarvamSttEndpoint),
    )
      ..headers.addAll(_headers)
      ..fields['language_code'] = locale
      ..files.add(http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: 'audio.wav',
      ));

    final streamed = await request.send().timeout(AppConstants.receiveTimeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw SarvamApiException(
        statusCode: streamed.statusCode,
        message: 'STT API error: $body',
      );
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return (json['transcript'] as String?) ??
        (json['text'] as String?) ??
        '';
  }

  // ---------------------------------------------------------------------------
  // Text-to-Speech (Sarvam hosted)
  // ---------------------------------------------------------------------------

  /// Synthesises [text] to speech using Sarvam's TTS API.
  /// Returns raw audio bytes (MP3/WAV).
  Future<List<int>> synthesiseSpeech({
    required String text,
    required String locale,
  }) async {
    final payload = {
      'text': text,
      'language_code': locale,
      'speaker': 'meera', // default Sarvam speaker — adjust as needed
    };

    final response = await _client
        .post(
          Uri.parse(AppConstants.sarvamTtsEndpoint),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(AppConstants.receiveTimeout);

    if (response.statusCode != 200) {
      throw SarvamApiException(
        statusCode: response.statusCode,
        message: 'TTS API error: ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final audioB64 = body['audio'] as String? ?? body['audio_base64'] as String?;
    if (audioB64 != null) return base64Decode(audioB64);
    return response.bodyBytes; // fallback: raw bytes
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AppConstants.sarvamApiKey.isNotEmpty)
          'Authorization': 'Bearer ${AppConstants.sarvamApiKey}',
      };

  Map<String, dynamic> _buildPayload({
    required List<ChatMessage> messages,
    required String locale,
    String? systemPrompt,
  }) {
    final messageList = <Map<String, String>>[];

    // System message: language + personality instruction.
    final system = systemPrompt ??
        'You are Fera, a helpful AI assistant. '
        'Always respond in the language with locale code "$locale". '
        'Be concise, friendly, and accurate.';

    messageList.add({'role': 'system', 'content': system});

    for (final msg in messages) {
      if (msg.role == MessageRole.system) continue; // avoid duplicate system
      messageList.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    return {
      'model': 'sarvam-1',
      'messages': messageList,
      'temperature': 0.7,
      'max_tokens': 512,
      'language_code': locale,
    };
  }

  String _extractContent(Map<String, dynamic> body) {
    final choices = body['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const SarvamApiException(
          statusCode: 0, message: 'Empty choices in API response');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    return (message?['content'] as String?) ?? '';
  }
}

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

class SarvamApiException implements Exception {
  final int statusCode;
  final String message;

  const SarvamApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'SarvamApiException($statusCode): $message';
}
