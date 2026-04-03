// lib/utils/intent_detector.dart

import 'package:fera_ai_assistant/models/ai_response.dart';

/// Classifies the user's intent from plain text so that [AssistantService]
/// can route the request to the correct handler without a round-trip to the AI.
///
/// Detection is keyword-based and language-agnostic (covers romanised Hindi
/// words and common English commands).  For high-accuracy intent detection in
/// all 22 languages you should complement this with a lightweight NLU call to
/// the Sarvam-1 model.
class IntentDetector {
  IntentDetector._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns a [DetectedIntent] for [text].
  static DetectedIntent detect(String text) {
    final lower = text.toLowerCase().trim();

    if (_matchesAction(lower)) {
      return DetectedIntent(
        type: IntentType.action,
        action: _resolveAction(lower),
        searchQuery: null,
      );
    }

    if (_requiresSearch(lower)) {
      return DetectedIntent(
        type: IntentType.search,
        action: null,
        searchQuery: _extractSearchQuery(lower),
      );
    }

    return const DetectedIntent(
      type: IntentType.conversation,
      action: null,
      searchQuery: null,
    );
  }

  // ---------------------------------------------------------------------------
  // Search intent helpers
  // ---------------------------------------------------------------------------

  static bool _requiresSearch(String text) {
    return _searchPatterns.any((pattern) => text.contains(pattern));
  }

  static String _extractSearchQuery(String text) {
    for (final trigger in _searchStripPrefixes) {
      if (text.startsWith(trigger)) {
        return text.substring(trigger.length).trim();
      }
    }
    return text;
  }

  static const List<String> _searchPatterns = [
    // English
    'search for', 'search ', 'look up', 'look for', 'find ', 'what is ',
    'who is ', 'when is ', 'where is ', 'how to ', 'latest news', 'news about',
    'tell me about', 'price of', 'weather in', 'weather today',
    // Hindi (romanised)
    'dhundh', 'batao', 'kya hai', 'kaun hai', 'kab hai', 'kahan hai',
    'kaise kare', 'khabar', 'news', 'mausam', 'keemat',
  ];

  static const List<String> _searchStripPrefixes = [
    'search for ', 'search ', 'look up ', 'find ', 'tell me about ',
    'what is ', 'who is ', 'when is ', 'where is ', 'how to ',
    'dhundh ', 'batao mujhe ', 'batao ',
  ];

  // ---------------------------------------------------------------------------
  // Action intent helpers
  // ---------------------------------------------------------------------------

  static bool _matchesAction(String text) {
    return _actionPatterns.keys.any((pattern) => text.contains(pattern));
  }

  static AssistantAction _resolveAction(String text) {
    for (final entry in _actionPatterns.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return AssistantAction.other;
  }

  /// Maps keyword fragments → [AssistantAction].
  static const Map<String, AssistantAction> _actionPatterns = {
    // YouTube
    'open youtube': AssistantAction.openYoutube,
    'youtube kholo': AssistantAction.openYoutube,
    'play youtube': AssistantAction.openYoutube,
    'search youtube': AssistantAction.searchYoutube,
    'youtube par dhundh': AssistantAction.searchYoutube,
    'play latest video': AssistantAction.playYoutubeLatest,
    'latest video of': AssistantAction.playYoutubeLatest,
    // Hardcoded shorthand patterns for MrBeast are intentional: they are the
    // specific example from the product spec ("search for MrBeast and play the
    // latest video"). The general patterns above handle all other creators.
    'latest mrbeast': AssistantAction.playYoutubeLatest,
    'mrbeast latest': AssistantAction.playYoutubeLatest,
    // WhatsApp
    'open whatsapp': AssistantAction.openWhatsApp,
    'whatsapp kholo': AssistantAction.openWhatsApp,
    // Maps
    'open maps': AssistantAction.openMaps,
    'navigate to': AssistantAction.openMaps,
    'directions to': AssistantAction.openMaps,
    // Browser
    'open browser': AssistantAction.openBrowser,
    'open website': AssistantAction.openBrowser,
    // Calls
    'call ': AssistantAction.makeCall,
    'phone karo': AssistantAction.makeCall,
    // SMS
    'send sms': AssistantAction.sendSms,
    'send message': AssistantAction.sendSms,
    'message bhejo': AssistantAction.sendSms,
    // Settings
    'open settings': AssistantAction.openSettings,
    'settings kholo': AssistantAction.openSettings,
    // Alarm
    'set alarm': AssistantAction.setAlarm,
    'alarm lagao': AssistantAction.setAlarm,
  };
}

// ---------------------------------------------------------------------------
// Value objects
// ---------------------------------------------------------------------------

enum IntentType { conversation, search, action }

class DetectedIntent {
  final IntentType type;
  final AssistantAction? action;

  /// Non-null when [type] is [IntentType.search].
  final String? searchQuery;

  const DetectedIntent({
    required this.type,
    required this.action,
    required this.searchQuery,
  });

  bool get isSearch => type == IntentType.search;
  bool get isAction => type == IntentType.action;
  bool get isConversation => type == IntentType.conversation;
}
