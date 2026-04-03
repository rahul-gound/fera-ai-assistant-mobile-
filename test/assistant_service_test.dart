// test/assistant_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fera_ai_assistant/models/ai_response.dart';
import 'package:fera_ai_assistant/models/chat_message.dart';
import 'package:fera_ai_assistant/models/search_result.dart';
import 'package:fera_ai_assistant/services/assistant_service.dart';
import 'package:fera_ai_assistant/services/sarvam_api_service.dart';
import 'package:fera_ai_assistant/services/search_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSarvamApiService extends Mock implements SarvamApiService {}

class MockSearchService extends Mock implements SearchService {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AssistantService sut;
  late MockSarvamApiService mockSarvam;
  late MockSearchService mockSearch;

  setUp(() {
    mockSarvam = MockSarvamApiService();
    mockSearch = MockSearchService();
    sut = AssistantService(
      sarvamApi: mockSarvam,
      searchService: mockSearch,
    );

    registerFallbackValue(const SearchResponse(query: '', results: []));
    registerFallbackValue(<ChatMessage>[]);
  });

  const locale = 'hi-IN';
  const aiReply = 'यह एक परीक्षण उत्तर है।';

  // ── Helper ────────────────────────────────────────────────────────────────
  void stubSarvamChat(String reply) {
    when(() => mockSarvam.chat(
          messages: any(named: 'messages'),
          locale: any(named: 'locale'),
          systemPrompt: any(named: 'systemPrompt'),
        )).thenAnswer((_) async => reply);
  }

  // ── Test cases ────────────────────────────────────────────────────────────

  group('AssistantService.processUserInput', () {
    test('empty input returns empty AIResponse without calling APIs', () async {
      final response = await sut.processUserInput(
        userText: '   ',
        locale: locale,
        history: [],
      );

      expect(response.displayText, isEmpty);
      verifyNever(() => mockSarvam.chat(
            messages: any(named: 'messages'),
            locale: any(named: 'locale'),
          ));
      verifyNever(() => mockSearch.search(any()));
    });

    test('conversation intent calls Sarvam without search', () async {
      stubSarvamChat(aiReply);

      final response = await sut.processUserInput(
        userText: 'तुम कैसे हो?', // "How are you?" — no search intent
        locale: locale,
        history: [],
      );

      expect(response.displayText, equals(aiReply));
      expect(response.usedWebSearch, isFalse);
      expect(response.triggeredAction, isFalse);
      verifyNever(() => mockSearch.search(any()));
      verify(() => mockSarvam.chat(
            messages: any(named: 'messages'),
            locale: locale,
            systemPrompt: any(named: 'systemPrompt'),
          )).called(1);
    });

    test('search intent calls SearchService and Sarvam', () async {
      const query = 'latest news';
      const searchResults = SearchResponse(
        query: query,
        results: [
          SearchResult(
            title: 'Breaking News',
            url: 'https://example.com',
            snippet: 'Something happened today.',
          )
        ],
      );

      when(() => mockSearch.search(any()))
          .thenAnswer((_) async => searchResults);
      stubSarvamChat(aiReply);

      final response = await sut.processUserInput(
        userText: 'latest news',
        locale: locale,
        history: [],
      );

      expect(response.usedWebSearch, isTrue);
      expect(response.displayText, equals(aiReply));
      verify(() => mockSearch.search(any())).called(1);
      verify(() => mockSarvam.chat(
            messages: any(named: 'messages'),
            locale: locale,
            systemPrompt: any(named: 'systemPrompt'),
          )).called(1);
    });

    test('action intent (open YouTube) returns confirmation without AI call',
        () async {
      final response = await sut.processUserInput(
        userText: 'open youtube',
        locale: locale,
        history: [],
      );

      expect(response.triggeredAction, isTrue);
      expect(response.action, isNotNull);
      // ActionService will fail gracefully in test environment; just confirm
      // no AI/search calls were made.
      verifyNever(() => mockSarvam.chat(
            messages: any(named: 'messages'),
            locale: any(named: 'locale'),
          ));
      verifyNever(() => mockSearch.search(any()));
    });

    test('Sarvam API error returns fallback message', () async {
      when(() => mockSarvam.chat(
            messages: any(named: 'messages'),
            locale: any(named: 'locale'),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenThrow(
            const SarvamApiException(statusCode: 503, message: 'Unavailable'),
          );

      final response = await sut.processUserInput(
        userText: 'नमस्ते',
        locale: locale,
        history: [],
      );

      expect(response.displayText, isNotEmpty);
      expect(response.displayText, isNot(throwsException));
    });

    test('spokenText has markdown stripped', () async {
      stubSarvamChat('**Bold** and *italic* text with [link](http://x.com)');

      final response = await sut.processUserInput(
        userText: 'tell me something',
        locale: 'en-IN',
        history: [],
      );

      expect(response.spokenText, isNot(contains('**')));
      expect(response.spokenText, isNot(contains('*')));
      expect(response.spokenText, isNot(contains('[link]')));
    });
  });
}
