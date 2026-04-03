// lib/services/stt_service.dart

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Wraps the `speech_to_text` plugin and exposes a simple stream-based API.
///
/// The device's on-board STT engine is used by default.  For production you may
/// want to fall back to [SarvamApiService.transcribeAudio] when the device
/// engine does not support the chosen Indian locale.
class SttService {
  SttService({SpeechToText? stt}) : _stt = stt ?? SpeechToText();

  final SpeechToText _stt;
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Must be called once before [startListening].
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(
      onError: (error) => _lastError = error.errorMsg,
      debugLogging: false,
    );
    return _initialized;
  }

  bool get isListening => _stt.isListening;
  bool get isAvailable => _initialized && _stt.isAvailable;

  String? _lastError;
  String? get lastError => _lastError;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Starts continuous listening in [locale] (e.g. `'hi-IN'`).
  ///
  /// [onResult] is called with each partial / final transcription.
  /// [onDone] is called when the session ends (timeout or [stopListening]).
  Future<void> startListening({
    required String locale,
    required void Function(String text, bool isFinal) onResult,
    void Function()? onDone,
  }) async {
    if (!_initialized) await initialize();
    _lastError = null;

    await _stt.listen(
      localeId: locale,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) onDone?.call();
      },
      listenMode: ListenMode.confirmation,
    );
  }

  /// Stops an active listening session.
  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }

  /// Cancels the session without firing [onResult].
  Future<void> cancel() async {
    if (_stt.isListening) await _stt.cancel();
  }

  /// Returns all locales supported by the device STT engine.
  Future<List<String>> availableLocales() async {
    if (!_initialized) await initialize();
    final locales = await _stt.locales();
    return locales.map((l) => l.localeId).toList();
  }

  void dispose() {
    _stt.cancel();
  }
}
