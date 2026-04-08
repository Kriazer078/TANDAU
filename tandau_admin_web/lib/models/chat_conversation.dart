import 'dart:convert';

/// Single chat message in a conversation
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });

  ChatMessage copyWith({String? text, bool? isUser, DateTime? time}) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'time': time.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'] as String? ?? '',
    isUser: json['isUser'] as bool? ?? false,
    time: json['time'] != null
        ? DateTime.parse(json['time'] as String)
        : DateTime.now(),
  );
}

/// A single AI chat conversation (like one "thread" in ChatGPT)
class ChatConversation {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  /// Auto-generate title from the first user message
  String get autoTitle {
    final firstUserMsg = messages.where((m) => m.isUser).firstOrNull;
    if (firstUserMsg == null) return title;
    final text = firstUserMsg.text;
    if (text.length <= 40) return text;
    return '${text.substring(0, 37)}...';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final msgs =
        (json['messages'] as List<dynamic>?)
            ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];
    return ChatConversation(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      messages: msgs,
    );
  }

  String encode() => jsonEncode(toJson());

  static ChatConversation decode(String source) =>
      ChatConversation.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
