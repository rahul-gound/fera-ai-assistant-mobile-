// lib/ui/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:fera_ai_assistant/models/chat_message.dart';
import 'package:fera_ai_assistant/services/assistant_service.dart';
import 'package:fera_ai_assistant/services/stt_service.dart';
import 'package:fera_ai_assistant/services/tts_service.dart';
import 'package:fera_ai_assistant/ui/widgets/chat_bubble.dart';
import 'package:fera_ai_assistant/ui/widgets/language_selector.dart';
import 'package:fera_ai_assistant/ui/widgets/voice_input_button.dart';
import 'package:fera_ai_assistant/utils/constants.dart';

/// Main chat screen.  Wires together STT → AssistantService → TTS.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ---------------------------------------------------------------------------
  // Services (could also be injected via a DI framework like get_it)
  // ---------------------------------------------------------------------------
  final _assistantService = AssistantService();
  final _sttService = SttService();
  final _ttsService = TtsService();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  VoiceInputState _voiceState = VoiceInputState.idle;
  String _locale = AppConstants.defaultLocale;
  String _partialTranscript = '';
  bool _ttsEnabled = true;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _sttService.initialize();
    await _ttsService.initialize();
  }

  @override
  void dispose() {
    _sttService.dispose();
    _ttsService.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Voice input
  // ---------------------------------------------------------------------------

  Future<void> _toggleListening() async {
    if (_voiceState == VoiceInputState.listening) {
      await _sttService.stopListening();
      setState(() => _voiceState = VoiceInputState.idle);
      return;
    }

    setState(() {
      _voiceState = VoiceInputState.listening;
      _partialTranscript = '';
    });

    await _sttService.startListening(
      locale: _locale,
      onResult: (text, isFinal) {
        setState(() => _partialTranscript = text);
        if (isFinal) _handleUserInput(text);
      },
      onDone: () => setState(() => _voiceState = VoiceInputState.idle),
    );
  }

  // ---------------------------------------------------------------------------
  // Text input
  // ---------------------------------------------------------------------------

  void _onSendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _handleUserInput(text);
  }

  // ---------------------------------------------------------------------------
  // Core pipeline
  // ---------------------------------------------------------------------------

  Future<void> _handleUserInput(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage.user(text: text, locale: _locale);
    setState(() {
      _messages.add(userMsg);
      _partialTranscript = '';
      _voiceState = VoiceInputState.processing;
    });
    _scrollToBottom();

    // Keep only the last N messages as history to control token usage.
    final window = _messages
        .where((m) => m.role != MessageRole.system)
        .toList()
        .reversed
        .take(AppConstants.maxChatHistory)
        .toList()
        .reversed
        .toList();

    final response = await _assistantService.processUserInput(
      userText: text,
      locale: _locale,
      history: window,
    );

    setState(() {
      _messages.add(response.asChatMessage);
      _voiceState = VoiceInputState.idle;
    });
    _scrollToBottom();

    if (_ttsEnabled && response.spokenText.isNotEmpty) {
      await _ttsService.speak(response.spokenText, locale: _locale);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fera AI'),
        centerTitle: false,
        actions: [
          LanguageSelector(
            currentLocale: _locale,
            onLocaleChanged: (locale) => setState(() => _locale = locale),
          ),
          IconButton(
            icon: Icon(_ttsEnabled ? Icons.volume_up : Icons.volume_off),
            tooltip: _ttsEnabled ? 'Mute TTS' : 'Enable TTS',
            onPressed: () async {
              setState(() => _ttsEnabled = !_ttsEnabled);
              if (!_ttsEnabled) await _ttsService.stop();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Message list ──────────────────────────────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length +
                        (_partialTranscript.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length &&
                          _partialTranscript.isNotEmpty) {
                        // Ghost bubble for partial transcript
                        return Opacity(
                          opacity: 0.5,
                          child: ChatBubble(
                            message: ChatMessage.user(
                              text: _partialTranscript,
                              locale: _locale,
                            ),
                          ),
                        );
                      }
                      final msg = _messages[index];
                      return ChatBubble(
                        message: msg,
                        onTap: msg.role == MessageRole.assistant
                            ? () => _ttsService.speak(
                                  msg.text,
                                  locale: msg.locale,
                                )
                            : null,
                      );
                    },
                  ),
          ),

          // ── Input row ─────────────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            // Text field
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _onSendText(),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button (text)
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _onSendText,
            ),
            const SizedBox(width: 4),

            // Voice button
            VoiceInputButton(
              state: _voiceState,
              onPressed: _voiceState == VoiceInputState.processing
                  ? () {} // disable while AI is thinking
                  : _toggleListening,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'नमस्ते! मैं Fera हूँ।\nबोलिए या लिखिए — मैं तैयार हूँ।',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
