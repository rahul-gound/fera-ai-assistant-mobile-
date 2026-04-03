// test/intent_detector_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:fera_ai_assistant/models/ai_response.dart';
import 'package:fera_ai_assistant/utils/intent_detector.dart';

void main() {
  group('IntentDetector', () {
    test('detects search intent for English keywords', () {
      final result = IntentDetector.detect('what is the price of gold');
      expect(result.type, IntentType.search);
    });

    test('detects search intent for Hindi romanised keywords', () {
      final result = IntentDetector.detect('aaj ka mausam batao');
      expect(result.type, IntentType.search);
    });

    test('detects open YouTube action', () {
      final result = IntentDetector.detect('open youtube');
      expect(result.type, IntentType.action);
      expect(result.action, AssistantAction.openYoutube);
    });

    test('detects play latest video action', () {
      final result = IntentDetector.detect('play latest video of MrBeast');
      expect(result.type, IntentType.action);
      expect(result.action, AssistantAction.playYoutubeLatest);
    });

    test('detects mrbeast latest shorthand', () {
      final result = IntentDetector.detect('mrbeast latest');
      expect(result.type, IntentType.action);
      expect(result.action, AssistantAction.playYoutubeLatest);
    });

    test('returns conversation for casual chat', () {
      final result = IntentDetector.detect('How are you?');
      expect(result.type, IntentType.conversation);
    });

    test('returns conversation for empty string', () {
      final result = IntentDetector.detect('');
      expect(result.type, IntentType.conversation);
    });

    test('sets searchQuery when search intent detected', () {
      final result = IntentDetector.detect('search for flutter tutorials');
      expect(result.searchQuery, 'flutter tutorials');
    });
  });
}
