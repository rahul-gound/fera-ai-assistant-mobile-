// lib/services/tts_service.dart

import 'package:flutter_tts/flutter_tts.dart';

/// Wraps the `flutter_tts` plugin for straightforward text-to-speech playback.
class TtsService {
  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
    );
    await _tts.awaitSpeakCompletion(true);
  }

  // ---------------------------------------------------------------------------
  // Playback API
  // ---------------------------------------------------------------------------

  /// Speaks [text] in [locale] (e.g. `'hi-IN'`).
  Future<void> speak(String text, {required String locale}) async {
    _isSpeaking = true;
    try {
      await _configureForLocale(locale);
      await _tts.speak(text);
    } finally {
      _isSpeaking = false;
    }
  }

  /// Stops any currently playing speech.
  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  // _isSpeaking is updated around speak() calls so callers can poll state.

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);
  Future<void> setVolume(double volume) => _tts.setVolume(volume);
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _configureForLocale(String locale) async {
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// Returns true if [locale] is available on this device.
  Future<bool> isLocaleAvailable(String locale) async {
    final languages = await _tts.getLanguages as List?;
    return languages?.contains(locale) ?? false;
  }

  void dispose() {
    _tts.stop();
  }
}
