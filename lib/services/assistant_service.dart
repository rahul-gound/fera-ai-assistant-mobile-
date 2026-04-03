// lib/services/assistant_service.dart
//
// ┌──────────────────────────────────────────────────────────────────────────┐
// │  AssistantService — the main orchestrator                                │
// │                                                                          │
// │  Pipeline for every user utterance:                                      │
// │  1. Receive voice-transcribed text (from SttService)                     │
// │  2. Detect intent (IntentDetector)                                       │
// │     a. ACTION  → execute via ActionService, skip AI                      │
// │     b. SEARCH  → call SearchService, inject results as AI context        │
// │     c. CONVO   → forward conversation history to Sarvam-1                │
// │  3. Call SarvamApiService.chat()                                         │
// │  4. Return AIResponse (display text + spoken text)                       │
// │  5. Caller passes spokenText to TtsService                               │
// └──────────────────────────────────────────────────────────────────────────┘

import 'package:fera_ai_assistant/models/ai_response.dart';
import 'package:fera_ai_assistant/models/chat_message.dart';
import 'package:fera_ai_assistant/models/search_result.dart';
import 'package:fera_ai_assistant/services/action_service.dart';
import 'package:fera_ai_assistant/services/sarvam_api_service.dart';
import 'package:fera_ai_assistant/services/search_service.dart';
import 'package:fera_ai_assistant/utils/constants.dart';
import 'package:fera_ai_assistant/utils/intent_detector.dart';

/// Orchestrates AI requests, web search, and device actions.
///
/// Inject via constructor for easy unit-testing.
class AssistantService {
  AssistantService({
    SarvamApiService? sarvamApi,
    SearchService? searchService,
  })  : _sarvamApi = sarvamApi ?? SarvamApiService(),
        _searchService = searchService ?? SearchService();

  final SarvamApiService _sarvamApi;
  final SearchService _searchService;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Processes [userText] and returns an [AIResponse] ready for display + TTS.
  ///
  /// [locale]   — BCP-47 locale the user is speaking in, e.g. `'hi-IN'`.
  /// [history]  — recent conversation messages (window of N messages).
  ///
  /// This is the **single entry-point** called by the UI after STT has produced
  /// a final transcript.
  Future<AIResponse> processUserInput({
    required String userText,
    required String locale,
    required List<ChatMessage> history,
  }) async {
    if (userText.trim().isEmpty) {
      return _emptyResponse(locale);
    }

    final intent = IntentDetector.detect(userText);

    // ── Branch 1: Device / app action ───────────────────────────────────────
    if (intent.isAction && intent.action != null) {
      return _handleAction(intent, userText, locale);
    }

    // ── Branch 2: Web search needed ──────────────────────────────────────────
    if (intent.isSearch && intent.searchQuery != null) {
      return _handleSearch(
        userText: userText,
        searchQuery: intent.searchQuery!,
        locale: locale,
        history: history,
      );
    }

    // ── Branch 3: Pure conversation ──────────────────────────────────────────
    return _handleConversation(
      userText: userText,
      locale: locale,
      history: history,
    );
  }

  // ---------------------------------------------------------------------------
  // Branch handlers
  // ---------------------------------------------------------------------------

  /// Executes a device/app action and returns a short confirmation response.
  Future<AIResponse> _handleAction(
    DetectedIntent intent,
    String userText,
    String locale,
  ) async {
    // Extract the argument (e.g. channel name) from the user text if present.
    final argument = _extractActionArgument(userText, intent.action!);

    final confirmationText =
        await ActionService.execute(intent.action!, argument: argument);

    return AIResponse(
      displayText: confirmationText,
      spokenText: confirmationText,
      locale: locale,
      triggeredAction: true,
      action: intent.action,
    );
  }

  /// Fetches web results, builds an augmented prompt, and calls the AI.
  Future<AIResponse> _handleSearch({
    required String userText,
    required String searchQuery,
    required String locale,
    required List<ChatMessage> history,
  }) async {
    final searchResponse = await _searchService.search(searchQuery);

    final systemPrompt = _buildSystemPrompt(
      locale: locale,
      searchContext: searchResponse.hasResults
          ? searchResponse.toPromptContext()
          : null,
    );

    final augmentedHistory = [
      ...history,
      ChatMessage.user(text: userText, locale: locale),
    ];

    String aiText;
    try {
      aiText = await _sarvamApi.chat(
        messages: augmentedHistory,
        locale: locale,
        systemPrompt: systemPrompt,
      );
    } on SarvamApiException catch (e) {
      aiText = _fallbackMessage(e, locale);
    }

    return AIResponse(
      displayText: aiText,
      spokenText: _stripMarkdownForSpeech(aiText),
      locale: locale,
      usedWebSearch: searchResponse.hasResults,
    );
  }

  /// Sends the conversation to Sarvam-1 without extra context injection.
  Future<AIResponse> _handleConversation({
    required String userText,
    required String locale,
    required List<ChatMessage> history,
  }) async {
    final systemPrompt = _buildSystemPrompt(locale: locale);

    final augmentedHistory = [
      ...history,
      ChatMessage.user(text: userText, locale: locale),
    ];

    String aiText;
    try {
      aiText = await _sarvamApi.chat(
        messages: augmentedHistory,
        locale: locale,
        systemPrompt: systemPrompt,
      );
    } on SarvamApiException catch (e) {
      aiText = _fallbackMessage(e, locale);
    }

    return AIResponse(
      displayText: aiText,
      spokenText: _stripMarkdownForSpeech(aiText),
      locale: locale,
    );
  }

  // ---------------------------------------------------------------------------
  // Prompt builder
  // ---------------------------------------------------------------------------

  String _buildSystemPrompt({required String locale, String? searchContext}) {
    final langName = AppConstants.supportedLanguages.entries
        .firstWhere(
          (e) => e.value == locale,
          orElse: () => const MapEntry('Hindi', 'hi-IN'),
        )
        .key;

    final buffer = StringBuffer(
      'You are Fera, an intelligent, voice-first AI assistant that supports '
      '22 Indian languages. '
      'The user is speaking in $langName (locale: $locale). '
      'ALWAYS respond in $langName using the same script the user used. '
      'Be helpful, concise, and culturally sensitive. '
      'When providing factual information, cite the source briefly.',
    );

    if (searchContext != null && searchContext.isNotEmpty) {
      buffer.writeln(
        '\n\nUse the following real-time web search results to inform your '
        'answer. Do not make up information beyond what is provided:\n',
      );
      buffer.write(searchContext);
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Strips markdown syntax so TTS does not read symbols aloud.
  String _stripMarkdownForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1') // bold
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1') // italic
        .replaceAll(RegExp(r'`(.+?)`'), r'$1') // inline code
        .replaceAll(RegExp(r'#+\s'), '') // headings
        .replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1') // links
        .replaceAll(RegExp(r'•\s'), '') // bullets
        .trim();
  }

  /// Tries to extract a meaningful argument from user text for an action
  /// (e.g. "play latest video of MrBeast" → "MrBeast").
  String? _extractActionArgument(String text, AssistantAction action) {
    final lower = text.toLowerCase();
    switch (action) {
      case AssistantAction.playYoutubeLatest:
        const triggers = [
          'latest video of ',
          'latest video by ',
          'new video of ',
          'new video by ',
        ];
        for (final t in triggers) {
          final idx = lower.indexOf(t);
          if (idx != -1) return text.substring(idx + t.length).trim();
        }
        return null;
      case AssistantAction.searchYoutube:
        const triggers = [
          'search youtube for ',
          'youtube par dhundh ',
          'youtube search ',
        ];
        for (final t in triggers) {
          final idx = lower.indexOf(t);
          if (idx != -1) return text.substring(idx + t.length).trim();
        }
        return null;
      case AssistantAction.makeCall:
        const triggers = ['call ', 'phone karo '];
        for (final t in triggers) {
          final idx = lower.indexOf(t);
          if (idx != -1) return text.substring(idx + t.length).trim();
        }
        return null;
      default:
        return null;
    }
  }

  AIResponse _emptyResponse(String locale) => AIResponse(
        displayText: '',
        spokenText: '',
        locale: locale,
      );

  String _fallbackMessage(SarvamApiException e, String locale) {
    // Generic fallback shown when the API is unreachable.
    if (locale.startsWith('hi')) {
      return 'माफ़ करें, अभी जवाब देने में समस्या है। कृपया दोबारा कोशिश करें।';
    }
    return 'Sorry, I could not get a response right now. Please try again.';
  }
}
