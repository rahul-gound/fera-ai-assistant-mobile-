# Fera AI Assistant

A voice-first Android app that supports **22 Indian languages**, powered by the **Sarvam-1 (2B)** Indic language model.

---

## Features

| Feature | Details |
|---|---|
| 🎙️ Voice Input (STT) | On-device STT via `speech_to_text`; falls back to Sarvam's hosted STT API |
| 🔊 Voice Output (TTS) | On-device TTS via `flutter_tts` |
| 💬 Chat UI | Markdown-aware chat bubbles with timestamps |
| 🌐 Web Search | Auto-detects search intent → queries `search.fera-search.tech` → injects results as AI context |
| 📱 Device Actions | Opens YouTube, WhatsApp, Maps, calls, SMS, alarm, and more via deep-links |
| 🇮🇳 22 Languages | Hindi, Bengali, Telugu, Marathi, Tamil, Gujarati, Urdu, Kannada, Odia, Malayalam, Punjabi, Assamese, Maithili, Santali, Kashmiri, Nepali, Sindhi, Dogri, Konkani, Manipuri, Bodo, Sanskrit |

---

## Architecture

```
lib/
├── main.dart                    ← entry point
├── app.dart                     ← MaterialApp + theming
├── models/
│   ├── chat_message.dart        ← ChatMessage, MessageRole
│   ├── search_result.dart       ← SearchResult, SearchResponse
│   └── ai_response.dart         ← AIResponse, AssistantAction
├── services/
│   ├── assistant_service.dart   ← 🌟 MAIN ORCHESTRATOR
│   ├── sarvam_api_service.dart  ← Sarvam-1 HTTP client (chat / STT / TTS)
│   ├── search_service.dart      ← Fera custom search API client
│   ├── stt_service.dart         ← Speech-to-Text wrapper
│   ├── tts_service.dart         ← Text-to-Speech wrapper
│   └── action_service.dart      ← Device actions (YouTube, Maps, etc.)
├── utils/
│   ├── constants.dart           ← API endpoints, locales, timeouts
│   └── intent_detector.dart     ← Keyword-based intent classification
└── ui/
    ├── screens/
    │   └── chat_screen.dart     ← Main screen wiring STT → AI → TTS
    └── widgets/
        ├── chat_bubble.dart     ← Per-message bubble widget
        ├── voice_input_button.dart
        └── language_selector.dart
```

### Request Pipeline (`AssistantService.processUserInput`)

```
User speaks / types
       │
       ▼
 IntentDetector.detect(text)
       │
   ┌───┴──────────────────────────┐
   │ ACTION        │ SEARCH       │ CONVERSATION
   │               │              │
   ▼               ▼              ▼
ActionService  SearchService  SarvamApiService.chat()
(url_launcher)   .search()    (direct conversation)
       │               │              │
       │         inject results       │
       │         as system prompt     │
       │               └──────────────┤
       │                              ▼
       │                    SarvamApiService.chat()
       │                              │
       └──────────────────────────────┤
                                      ▼
                              AIResponse
                     { displayText, spokenText }
                                      │
                         ┌────────────┴─────────┐
                         ▼                      ▼
                    ChatBubble             TtsService
                  (displayed in UI)       .speak(text)
```

---

## Getting Started

### Prerequisites

- Flutter ≥ 3.19 (Dart ≥ 3.0)
- Android SDK ≥ 21 (Android 5.0)
- A Sarvam AI API key — [apply here](https://www.sarvam.ai/)

### Environment Setup

The Sarvam API key is read from the `--dart-define` flag at build time so it is **never committed to source control**:

```bash
flutter run --dart-define=SARVAM_API_KEY=your_key_here
```

For release builds:

```bash
flutter build apk --dart-define=SARVAM_API_KEY=your_key_here
```

### Run

```bash
flutter pub get
flutter run
```

### Test

```bash
flutter test
```

---

## Search API

The app uses a custom SearXNG-compatible endpoint:

```
GET https://search.fera-search.tech/?q={query}&safesearch=1&categories=general
```

The response must follow the SearXNG JSON format:
```json
{
  "results": [
    { "title": "...", "url": "...", "content": "..." }
  ]
}
```

---

## Special Actions (Examples)

| User says | What happens |
|---|---|
| "open YouTube" | Opens YouTube in browser/app |
| "play latest video of MrBeast" | Searches YouTube for "MrBeast latest video" |
| "search YouTube for cooking" | Opens YouTube search for "cooking" |
| "navigate to Connaught Place" | Opens Google Maps directions |
| "call 9876543210" | Initiates phone call |
| "set alarm for 7am" | Opens Android alarm intent |

---

## Adding a New Language

1. Add the locale to `AppConstants.supportedLanguages` in `lib/utils/constants.dart`.
2. Verify that `flutter_tts` and `speech_to_text` support the locale on your target device.
3. Add any new romanised trigger words to `IntentDetector` for better intent detection.