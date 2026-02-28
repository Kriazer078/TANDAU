import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_conversation.dart';

/// Manages multiple AI chat conversations (like ChatGPT history).
///
/// Each conversation is stored separately to avoid loading all messages
/// at once, which prevents lag with many messages.
class ChatHistoryService {
  // ── Singleton ──
  static final ChatHistoryService _instance = ChatHistoryService._internal();
  factory ChatHistoryService() => _instance;
  ChatHistoryService._internal();

  static const _indexKey = 'ai_conversations_index';
  static const _convPrefix = 'ai_conv_';
  static const _activeKey = 'ai_active_conversation';

  /// Generate a unique ID from timestamp + hashCode
  static String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().hashCode.abs()}';

  /// Reactive list of conversation metadata (id, title, dates)
  final ValueNotifier<List<ChatConversation>> conversations =
      ValueNotifier<List<ChatConversation>>([]);

  /// Currently active conversation ID
  final ValueNotifier<String?> activeConversationId = ValueNotifier<String?>(
    null,
  );

  bool _initialized = false;

  // ── Init ──

  /// Load conversation index from SharedPreferences
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _loadIndex();

    // Migrate old single-chat history if exists
    await _migrateOldHistory();
  }

  // ── CRUD ──

  /// Create a new empty conversation and set it as active
  ChatConversation createConversation() {
    final now = DateTime.now();
    final conv = ChatConversation(
      id: _generateId(),
      title: '',
      createdAt: now,
      updatedAt: now,
    );
    final list = List<ChatConversation>.from(conversations.value);
    list.insert(0, conv);
    conversations.value = list;
    activeConversationId.value = conv.id;
    _saveIndex();
    return conv;
  }

  /// Delete a conversation by ID
  Future<void> deleteConversation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_convPrefix$id');

    final list = List<ChatConversation>.from(conversations.value);
    list.removeWhere((c) => c.id == id);
    conversations.value = list;

    // If we deleted the active one, switch to the first available
    if (activeConversationId.value == id) {
      activeConversationId.value = list.isNotEmpty ? list.first.id : null;
    }
    await _saveIndex();
  }

  /// Get full conversation with messages (loads from storage)
  Future<ChatConversation?> getConversation(String id) async {
    // Check in-memory first
    final inMemory = conversations.value.where((c) => c.id == id).firstOrNull;
    if (inMemory != null && inMemory.messages.isNotEmpty) {
      return inMemory;
    }

    // Load from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_convPrefix$id');
      if (data != null) {
        final conv = ChatConversation.decode(data);
        // Update in-memory list with loaded messages
        _updateInMemory(conv);
        return conv;
      }
    } catch (e) {
      debugPrint('Failed to load conversation $id: $e');
    }
    return inMemory;
  }

  /// Set active conversation and load its messages
  Future<ChatConversation?> setActive(String id) async {
    activeConversationId.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, id);
    return getConversation(id);
  }

  /// Add a message to the active conversation
  Future<void> addMessage(ChatMessage message) async {
    final activeId = activeConversationId.value;
    if (activeId == null) return;

    final conv = await getConversation(activeId);
    if (conv == null) return;

    conv.messages.add(message);
    conv.updatedAt = DateTime.now();

    // Auto-title from first user message
    if (conv.title.isEmpty && message.isUser) {
      conv.title = conv.autoTitle;
    }

    _updateInMemory(conv);
    await _saveConversation(conv);
    await _saveIndex();
  }

  /// Replace all messages (e.g. after clear)
  Future<void> setMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    final conv = await getConversation(conversationId);
    if (conv == null) return;
    conv.messages = messages;
    conv.updatedAt = DateTime.now();
    _updateInMemory(conv);
    await _saveConversation(conv);
  }

  /// Get messages for the active conversation
  Future<List<ChatMessage>> getActiveMessages() async {
    final activeId = activeConversationId.value;
    if (activeId == null) return [];
    final conv = await getConversation(activeId);
    return conv?.messages ?? [];
  }

  // ── Storage ──

  Future<void> _saveConversation(ChatConversation conv) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_convPrefix${conv.id}', conv.encode());
    } catch (e) {
      debugPrint('Failed to save conversation: $e');
    }
  }

  Future<void> _saveIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = conversations.value
          .map(
            (c) => {
              'id': c.id,
              'title': c.title,
              'createdAt': c.createdAt.toIso8601String(),
              'updatedAt': c.updatedAt.toIso8601String(),
            },
          )
          .toList();
      await prefs.setString(_indexKey, jsonEncode(index));
    } catch (e) {
      debugPrint('Failed to save index: $e');
    }
  }

  Future<void> _loadIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_indexKey);
      if (data == null) return;

      final list = jsonDecode(data) as List;
      final convs = list.map((item) {
        final map = item as Map<String, dynamic>;
        return ChatConversation(
          id: map['id'] as String,
          title: map['title'] as String? ?? '',
          createdAt: DateTime.parse(map['createdAt'] as String),
          updatedAt: DateTime.parse(map['updatedAt'] as String),
        );
      }).toList();

      // Sort by updatedAt descending (newest first)
      convs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      conversations.value = convs;

      // Restore active conversation
      final activeId = prefs.getString(_activeKey);
      if (activeId != null && convs.any((c) => c.id == activeId)) {
        activeConversationId.value = activeId;
      } else if (convs.isNotEmpty) {
        activeConversationId.value = convs.first.id;
      }
    } catch (e) {
      debugPrint('Failed to load conversation index: $e');
    }
  }

  /// Migrate old single-chat history to the new multi-conversation format
  Future<void> _migrateOldHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldData = prefs.getString('ai_chat_history');
      if (oldData == null) return;

      final oldList = jsonDecode(oldData) as List;
      if (oldList.isEmpty) {
        await prefs.remove('ai_chat_history');
        return;
      }

      final messages = oldList.map((item) {
        final map = item as Map<String, dynamic>;
        return ChatMessage(
          text: map['text'] as String? ?? '',
          isUser: map['isUser'] as bool? ?? false,
          time: map['time'] != null
              ? DateTime.parse(map['time'] as String)
              : DateTime.now(),
        );
      }).toList();

      // Create a conversation from old messages
      final firstTime = messages.first.time;
      final conv = ChatConversation(
        id: _generateId(),
        title: '',
        createdAt: firstTime,
        updatedAt: messages.last.time,
        messages: messages,
      );
      conv.title = conv.autoTitle;

      // Save as new conversation
      final list = List<ChatConversation>.from(conversations.value);
      list.insert(0, conv);
      conversations.value = list;
      activeConversationId.value = conv.id;

      await _saveConversation(conv);
      await _saveIndex();

      // Remove old key
      await prefs.remove('ai_chat_history');
      debugPrint('Migrated old chat history to conversation ${conv.id}');
    } catch (e) {
      debugPrint('Failed to migrate old history: $e');
    }
  }

  void _updateInMemory(ChatConversation conv) {
    final list = List<ChatConversation>.from(conversations.value);
    final idx = list.indexWhere((c) => c.id == conv.id);
    if (idx >= 0) {
      list[idx] = conv;
    } else {
      list.insert(0, conv);
    }
    // Re-sort by updatedAt
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    conversations.value = list;
  }
}
