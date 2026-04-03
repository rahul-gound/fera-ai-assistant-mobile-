// lib/models/ai_response.dart

import 'package:fera_ai_assistant/models/chat_message.dart';

/// Holds the processed response from [AssistantService].
/// This is the object handed to the UI layer.
class AIResponse {
  /// The text that should be displayed in a chat bubble.
  final String displayText;

  /// The text that should be spoken aloud via TTS.
  /// May differ from [displayText] (e.g., markdown stripped for speech).
  final String spokenText;

  /// The language locale in which the response was generated.
  final String locale;

  /// Whether the response was augmented with a web-search context.
  final bool usedWebSearch;

  /// Whether the response triggered a device/app action.
  final bool triggeredAction;

  /// Optional: the action type that was executed.
  final AssistantAction? action;

  /// Full [ChatMessage] ready to be appended to the conversation list.
  ChatMessage get asChatMessage => ChatMessage.assistant(
        text: displayText,
        locale: locale,
      );

  const AIResponse({
    required this.displayText,
    required this.spokenText,
    required this.locale,
    this.usedWebSearch = false,
    this.triggeredAction = false,
    this.action,
  });
}

/// Possible special actions the assistant can perform on the device.
enum AssistantAction {
  openYoutube,
  searchYoutube,
  playYoutubeLatest,
  openWhatsApp,
  openMaps,
  openBrowser,
  makeCall,
  sendSms,
  openSettings,
  setAlarm,
  other,
}
