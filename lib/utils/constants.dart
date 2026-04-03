// lib/utils/constants.dart

/// Central place for all API endpoints, keys, and app-wide constants.
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------------
  // Sarvam-1 AI API
  // ---------------------------------------------------------------------------

  /// Base URL for the Sarvam AI REST API.
  /// Replace with the actual endpoint once the Sarvam-1 2B model is deployed.
  static const String sarvamBaseUrl = 'https://api.sarvam.ai/v1';

  /// Chat / completion endpoint.
  static const String sarvamChatEndpoint = '$sarvamBaseUrl/chat/completions';

  /// STT endpoint (if using Sarvam's hosted STT).
  static const String sarvamSttEndpoint = '$sarvamBaseUrl/speech-to-text';

  /// TTS endpoint (if using Sarvam's hosted TTS).
  static const String sarvamTtsEndpoint = '$sarvamBaseUrl/text-to-speech';

  /// Set via environment / secure storage — never hard-code real keys.
  static const String sarvamApiKey = String.fromEnvironment(
    'SARVAM_API_KEY',
    defaultValue: '',
  );

  // ---------------------------------------------------------------------------
  // Custom Search API
  // ---------------------------------------------------------------------------

  /// Fera search API base URL.
  static const String feraSearchBaseUrl = 'https://search.fera-search.tech/';

  /// Builds a search URL for [query].
  static String feraSearchUrl(String query) =>
      '$feraSearchBaseUrl?q=${Uri.encodeQueryComponent(query)}&safesearch=1&categories=general';

  // ---------------------------------------------------------------------------
  // Supported Indian Languages
  // ---------------------------------------------------------------------------

  /// Map of language name → BCP-47 locale code used by STT/TTS.
  static const Map<String, String> supportedLanguages = {
    'Hindi': 'hi-IN',
    'Bengali': 'bn-IN',
    'Telugu': 'te-IN',
    'Marathi': 'mr-IN',
    'Tamil': 'ta-IN',
    'Gujarati': 'gu-IN',
    'Urdu': 'ur-IN',
    'Kannada': 'kn-IN',
    'Odia': 'or-IN',
    'Malayalam': 'ml-IN',
    'Punjabi': 'pa-IN',
    'Assamese': 'as-IN',
    'Maithili': 'mai-IN',
    'Santali': 'sat-IN',
    'Kashmiri': 'ks-IN',
    'Nepali': 'ne-IN',
    'Sindhi': 'sd-IN',
    'Dogri': 'doi-IN',
    'Konkani': 'kok-IN',
    'Manipuri': 'mni-IN',
    'Bodo': 'brx-IN',
    'Sanskrit': 'sa-IN',
  };

  /// Default language on first launch.
  static const String defaultLanguageKey = 'Hindi';
  static const String defaultLocale = 'hi-IN';

  // ---------------------------------------------------------------------------
  // HTTP timeouts
  // ---------------------------------------------------------------------------
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // Misc
  // ---------------------------------------------------------------------------
  static const int maxSearchResults = 5;
  static const int maxChatHistory = 50; // messages kept in memory
}
