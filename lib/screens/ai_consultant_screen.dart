import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/ai_consultant_service.dart';
import '../services/ai_feedback_service.dart';
import '../services/auth_service.dart';
import '../services/moderation_service.dart';
import '../widgets/ai_logo_icon.dart';
import 'onboarding_wizard_screen.dart';

class AIConsultantScreen extends StatefulWidget {
  const AIConsultantScreen({super.key});

  @override
  State<AIConsultantScreen> createState() => _AIConsultantScreenState();
}

class _AIConsultantScreenState extends State<AIConsultantScreen>
    with SingleTickerProviderStateMixin {
  final AIConsultantService _aiService = AIConsultantService();
  final ModerationService _moderationService = ModerationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _fadeController;

  static const _historyPrefsKey = 'ai_chat_history';

  @override
  void initState() {
    super.initState();
    _aiService.init();
    _loadHistory();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeController.forward();
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _messages
          .map(
            (m) => {
              'text': m.text,
              'isUser': m.isUser,
              'time': m.time.toIso8601String(),
            },
          )
          .toList();
      await prefs.setString(_historyPrefsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Failed to save history: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_historyPrefsKey);
      if (str != null) {
        final list = jsonDecode(str) as List;
        setState(() {
          _messages.clear();
          for (final item in list) {
            _messages.add(
              _ChatMessage(
                text: item['text'],
                isUser: item['isUser'] ?? false,
                time: item['time'] != null
                    ? DateTime.parse(item['time'])
                    : DateTime.now(),
              ),
            );
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════
  //  SEND MESSAGE
  // ═══════════════════════════════════════════
  Future<void> _sendMessage({String? text}) async {
    final messageText = text ?? _messageController.text.trim();
    if (messageText.isEmpty) return;

    final l10n = AppLocalizations.of(context);

    // Moderation check
    if (_moderationService.isSpamming()) {
      _showErrorSnackBar(l10n?.moderationSpam ?? 'Подождите немного...');
      return;
    }

    if (_moderationService.hasProfanity(messageText)) {
      _showErrorSnackBar(
        l10n?.moderationProfanity ?? 'Нецензурная лексика запрещена',
      );
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(text: messageText, isUser: true, time: DateTime.now()),
      );
      _isTyping = true;
    });

    _saveHistory();

    _messageController.clear();
    _scrollToBottom();

    // Get current user profile for context
    final user = AuthService().currentUser.value;

    // Prepare history
    final history = _messages
        .where((m) => m != _messages.last) // Skip the message we just added
        .map((m) => {'text': m.text, 'isUser': m.isUser})
        .toList();

    // Limit history to last 10 messages for performance and token limits
    final recentHistory = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    try {
      final response = await _aiService.sendMessage(
        messageText,
        history: recentHistory,
        entScore: user?.untScore,
        ieltsScore: user?.ieltsScore,
        gpa: user?.gpa,
        mathScore: user?.mathScore,
        currentEducation: user?.education,
        preferredCities: user?.city != null ? [user!.city!] : null,
        userAchievements: user?.achievements,
        preferredMajors: user?.preferredMajors,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            _ChatMessage(text: response, isUser: false, time: DateTime.now()),
          );
        });
        _saveHistory();
        _scrollToBottom();
      }
    } on OutOfTokensException catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            _ChatMessage(text: e.message, isUser: false, time: DateTime.now()),
          );
        });
        _saveHistory();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            _ChatMessage(
              text: l10n?.aiError ?? 'Произошла ошибка. Попробуйте позже.',
              isUser: false,
              time: DateTime.now(),
            ),
          );
        });
        _saveHistory();
        _scrollToBottom();
      }
    }
  }

  /// Request Жеке Жоспар (personalized admission plan)
  Future<void> _requestZhekeZhospar() async {
    final l10n = AppLocalizations.of(context);

    setState(() {
      _messages.add(
        _ChatMessage(
          text: '📋 Создай мне Жеке Жоспар (персональный план поступления)',
          isUser: true,
          time: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    final user = AuthService().currentUser.value;

    try {
      final response = await _aiService.requestZhekeZhospar(
        entScore: user?.untScore,
        gpa: user?.gpa,
        ieltsScore: user?.ieltsScore,
        mathScore: user?.mathScore,
        city: user?.city,
        preferredMajors: user?.preferredMajors.join(', '),
        currentEducation: user?.education,
        achievements: user?.achievements.join(', '),
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            _ChatMessage(text: response, isUser: false, time: DateTime.now()),
          );
        });
        _saveHistory();
        _scrollToBottom();
      }
    } on OutOfTokensException catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            _ChatMessage(text: e.message, isUser: false, time: DateTime.now()),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            _ChatMessage(
              text: l10n?.aiError ?? 'Произошла ошибка. Попробуйте позже.',
              isUser: false,
              time: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
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

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const AILogoIcon(size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.aiAgentTitle ?? 'AI Consultant',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Online',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearChatDialog(context);
              } else if (value == 'about') {
                _showAboutDialog(context);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)?.aiClearChat ??
                          'Очистить чат',
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)?.aiAbout ?? 'О TANDAU AI',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Divider under AppBar
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.border,
          ),
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeState(context, isDark)
                : _buildChatList(isDark),
          ),
          _buildInputArea(context, isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  WELCOME STATE (empty chat)
  // ═══════════════════════════════════════════
  Widget _buildWelcomeState(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);

    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // AI Icon
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),

            // Title
            Text(
              l10n?.aiAgentWelcome ?? 'Чем могу помочь?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              l10n?.aiAgentSubtitle ??
                  'Анализирую данные вузов, чтобы найти лучший вариант для вас.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 🚀 Onboarding Wizard button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnboardingWizardScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    _sendMessage(
                      text: 'Мой профиль обновлён! Покажи мне подходящие вузы.',
                    );
                  }
                },
                icon: const Text('🚀', style: TextStyle(fontSize: 18)),
                label: const Text(
                  'Заполни профиль за 2 мин',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Suggestion chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(
                  l10n?.aiAgentSample1 ?? 'Лучшие для IT?',
                  Icons.computer_rounded,
                  isDark,
                ),
                _buildSuggestionChip(
                  l10n?.aiAgentSample2 ?? 'Требования для поступления',
                  Icons.school_rounded,
                  isDark,
                ),
                _buildSuggestionChip(
                  l10n?.aiAgentSample3 ?? 'Гранты 2026',
                  Icons.emoji_events_rounded,
                  isDark,
                ),
                _buildSuggestionChip(
                  '📖 Истории успеха',
                  Icons.auto_stories_rounded,
                  isDark,
                ),
                _buildZhekeZhosparChip(isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, IconData icon, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendMessage(text: label),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZhekeZhosparChip(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _requestZhekeZhospar,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                  : [const Color(0xFF818CF8), const Color(0xFFA78BFA)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_rounded, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                '📋 Жеке Жоспар',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  CHAT LIST
  // ═══════════════════════════════════════════
  Widget _buildChatList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator(isDark);
        }
        return _buildMessageBubble(_messages[index], isDark);
      },
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                _AnimatedTypingIndicator(isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, bool isDark) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? null
                  : (isDark ? AppColors.cardDark : AppColors.background),
              gradient: isUser
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
            ),
            child: isUser
                ? Text(
                    msg.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  )
                : MarkdownBody(
                    data: msg.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                      h1: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      listBullet: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                      horizontalRuleDecoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 4,
              right: isUser ? 4 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.time),
                  style: TextStyle(
                    color: isDark ? Colors.white24 : AppColors.textHint,
                    fontSize: 10,
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Рекомендация скопирована'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Скопировать',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FeedbackButtons(isDark: isDark, messageText: msg.text),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════════
  //  INPUT AREA
  // ═══════════════════════════════════════════
  Widget _buildInputArea(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText:
                    AppLocalizations.of(context)?.aiAgentInputHint ??
                    'Задайте вопрос...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.textHint,
                ),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _sendMessage(),
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  DIALOGS
  // ═══════════════════════════════════════════
  void _showClearChatDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.aiClearDialogTitle ?? 'Очистить историю?'),
        content: Text(
          l10n?.aiClearDialogContent ??
              'Все сообщения будут удалены безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.commonCancel ?? 'Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _messages.clear());
              _saveHistory();
              Navigator.pop(ctx);
            },
            child: Text(
              l10n?.aiClearDialogConfirm ?? 'Очистить',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const AILogoIcon(color: AppColors.primary),
            const SizedBox(width: 12),
            Text(l10n?.aiAbout ?? 'TANDAU AI'),
          ],
        ),
        content: Text(
          l10n?.aiAboutDialogContent ??
              'Использую современные алгоритмы для анализа данных вузов. Помогу найти лучшее место для учёбы и оценить шансы на поступление.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.aiAboutDialogButton ?? 'Понятно'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}

// ═══════════════════════════════════════════
//  TYPED MESSAGE MODEL (replaces Map<String, dynamic>)
// ═══════════════════════════════════════════
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

// ═══════════════════════════════════════════
//  ANIMATED TYPING INDICATOR
// ═══════════════════════════════════════════
class _AnimatedTypingIndicator extends StatefulWidget {
  final bool isDark;
  const _AnimatedTypingIndicator({required this.isDark});

  @override
  State<_AnimatedTypingIndicator> createState() =>
      _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<_AnimatedTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        String dots = '';
        if (val < 0.25) {
          dots = '';
        } else if (val < 0.5) {
          dots = '.';
        } else if (val < 0.75) {
          dots = '..';
        } else {
          dots = '...';
        }

        return Text(
          'Анализирую и генерирую ответ$dots',
          style: TextStyle(
            color: widget.isDark ? Colors.white54 : AppColors.textHint,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
//  FEEDBACK BUTTONS (👍👎)
// ═══════════════════════════════════════════
class _FeedbackButtons extends StatefulWidget {
  final bool isDark;
  final String messageText;
  const _FeedbackButtons({required this.isDark, required this.messageText});

  @override
  State<_FeedbackButtons> createState() => _FeedbackButtonsState();
}

class _FeedbackButtonsState extends State<_FeedbackButtons> {
  bool? _isHelpful; // true for 👍, false for 👎, null for none

  void _handleFeedback(bool isHelpful) {
    if (_isHelpful != null) return; // Prevent double feedback
    setState(() => _isHelpful = isHelpful);

    // 💾 Save feedback to Firestore
    AIFeedbackService().saveFeedback(
      isHelpful: isHelpful,
      aiResponse: widget.messageText,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHelpful ? 'Спасибо за отзыв! 👍' : 'Спасибо, мы учтём это! 👎',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: widget.isDark
            ? AppColors.surfaceDark
            : AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isHelpful != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(
              _isHelpful!
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_down_alt_rounded,
              size: 14,
              color: _isHelpful! ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              'Оценено',
              style: TextStyle(
                color: widget.isDark ? Colors.white54 : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        InkWell(
          onTap: () => _handleFeedback(true),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Icon(
              Icons.thumb_up_alt_outlined,
              size: 14,
              color: widget.isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () => _handleFeedback(false),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Icon(
              Icons.thumb_down_alt_outlined,
              size: 14,
              color: widget.isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
