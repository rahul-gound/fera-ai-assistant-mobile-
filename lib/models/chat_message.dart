// lib/models/chat_message.dart

/// Represents a single message in the chat conversation.
class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;

  /// Optional: raw audio bytes if the message was originally spoken.
  final String? audioBase64;

  /// Language locale in which this message was composed (e.g. 'hi-IN').
  final String locale;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    required this.locale,
    this.audioBase64,
  });

  factory ChatMessage.user({
    required String text,
    required String locale,
    String? audioBase64,
  }) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      locale: locale,
      audioBase64: audioBase64,
    );
  }

  factory ChatMessage.assistant({
    required String text,
    required String locale,
  }) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      locale: locale,
    );
  }

  factory ChatMessage.system(String text) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      role: MessageRole.system,
      timestamp: DateTime.now(),
      locale: 'en-IN',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'role': role.name,
        'timestamp': timestamp.toIso8601String(),
        'locale': locale,
        if (audioBase64 != null) 'audioBase64': audioBase64,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        text: json['text'] as String,
        role: MessageRole.values.byName(json['role'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        locale: json['locale'] as String,
        audioBase64: json['audioBase64'] as String?,
      );

  ChatMessage copyWith({String? text}) => ChatMessage(
        id: id,
        text: text ?? this.text,
        role: role,
        timestamp: timestamp,
        locale: locale,
        audioBase64: audioBase64,
      );
}

enum MessageRole { user, assistant, system }
