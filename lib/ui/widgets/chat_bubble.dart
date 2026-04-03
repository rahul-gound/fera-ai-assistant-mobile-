// lib/ui/widgets/chat_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fera_ai_assistant/models/chat_message.dart';

/// A single message bubble in the chat conversation.
///
/// User messages are aligned right with a coloured background;
/// assistant messages are aligned left in white/light-grey.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.onTap});

  final ChatMessage message;

  /// Optional: tap callback (e.g. to replay TTS for this bubble).
  final VoidCallback? onTap;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: _isUser ? 56 : 12,
            right: _isUser ? 12 : 56,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isUser
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: _isUser
                  ? const Radius.circular(18)
                  : const Radius.circular(4),
              bottomRight: _isUser
                  ? const Radius.circular(4)
                  : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Render markdown in AI responses for rich formatting.
              if (!_isUser)
                MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                )
              else
                Text(
                  message.text,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 15,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: _isUser
                      ? colorScheme.onPrimary.withOpacity(0.6)
                      : colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
