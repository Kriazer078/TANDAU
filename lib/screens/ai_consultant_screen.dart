import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_conversation.dart';
import '../services/ai_consultant_service.dart';
import '../services/ai_feedback_service.dart';
import '../services/auth_service.dart';
import '../services/chat_history_service.dart';
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
  final ChatHistoryService _historyService = ChatHistoryService();
  final ModerationService _moderationService = ModerationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isZhekeZhospar = false;
  int _thinkingStep = 0;
  Timer? _thinkingTimer;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _aiService.init();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeController.forward();
    _initHistory();
  }

  Future<void> _initHistory() async {
    await _historyService.init();
    await _loadActiveConversation();
  }

  Future<void> _loadActiveConversation() async {
    final activeId = _historyService.activeConversationId.value;
    if (activeId == null) {
      setState(() => _messages.clear());
      return;
    }
    final conv = await _historyService.getConversation(activeId);
    if (conv != null && mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(conv.messages);
      });
      _scrollToBottom();
    }
  }

  Future<void> _switchConversation(String id) async {
    final conv = await _historyService.setActive(id);
    if (conv != null && mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(conv.messages);
      });
      _scrollToBottom();
    }
    if (mounted) Navigator.pop(context); // close drawer
  }

  void _createNewChat() {
    _historyService.createConversation();
    setState(() => _messages.clear());
    _fadeController.reset();
    _fadeController.forward();
    Navigator.pop(context); // close drawer
  }

  @override
  void dispose() {
    _thinkingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _currentQuery = '';

  void _startThinkingSteps({bool isZheke = false, String message = ''}) {
    _thinkingTimer?.cancel();
    setState(() {
      _thinkingStep = 0;
      _isZhekeZhospar = isZheke;
      _currentQuery = message;
    });
    final isSimple = _isSimpleQuery(message);
    final maxSteps = isZheke ? 5 : (isSimple ? 2 : 4);
    final interval = isSimple ? 600 : 1200;
    _thinkingTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_thinkingStep < maxSteps - 1) {
        setState(() => _thinkingStep++);
        _scrollToBottom();
      } else {
        timer.cancel();
      }
    });
  }

  /// Определяет простой ли запрос (приветствие, короткий вопрос)
  bool _isSimpleQuery(String query) {
    final lower = query.toLowerCase().trim();
    if (lower.length < 15) return true;
    const greetings = [
      'привет',
      'салем',
      'здравствуй',
      'хай',
      'hi',
      'hello',
      'что умеешь',
      'кто ты',
      'как дела',
      'спасибо',
      'ок',
    ];
    return greetings.any((g) => lower.contains(g));
  }

  void _stopThinkingSteps() {
    _thinkingTimer?.cancel();
    _thinkingTimer = null;
  }

  // ═══════════════════════════════════════════
  //  ENSURE ACTIVE CONVERSATION
  // ═══════════════════════════════════════════
  Future<void> _ensureActiveConversation() async {
    if (_historyService.activeConversationId.value == null) {
      _historyService.createConversation();
    }
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

    // Auto-create conversation if needed
    await _ensureActiveConversation();

    final userMsg = ChatMessage(
      text: messageText,
      isUser: true,
      time: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _startThinkingSteps(message: messageText);

    unawaited(_historyService.addMessage(userMsg));

    _messageController.clear();
    _scrollToBottom();

    // Get current user profile for context
    final user = AuthService().currentUser.value;

    // Prepare history — limit to last 10 for performance
    final history = _messages
        .where((m) => m != _messages.last)
        .map((m) => {'text': m.text, 'isUser': m.isUser})
        .toList();
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
        _stopThinkingSteps();
        final aiMsg = ChatMessage(
          text: response,
          isUser: false,
          time: DateTime.now(),
        );
        setState(() {
          _isTyping = false;
          _messages.add(aiMsg);
        });
        unawaited(_historyService.addMessage(aiMsg));
        _scrollToBottom();
      }
    } on OutOfTokensException catch (e) {
      if (mounted) {
        _stopThinkingSteps();
        final errMsg = ChatMessage(
          text: e.message,
          isUser: false,
          time: DateTime.now(),
        );
        setState(() {
          _isTyping = false;
          _messages.add(errMsg);
        });
        unawaited(_historyService.addMessage(errMsg));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        _stopThinkingSteps();
        final errMsg = ChatMessage(
          text: l10n?.aiError ?? 'Произошла ошибка. Попробуйте позже.',
          isUser: false,
          time: DateTime.now(),
        );
        setState(() {
          _isTyping = false;
          _messages.add(errMsg);
        });
        unawaited(_historyService.addMessage(errMsg));
        _scrollToBottom();
      }
    }
  }

  /// Request Жеке Жоспар (personalized admission plan)
  Future<void> _requestZhekeZhospar() async {
    final l10n = AppLocalizations.of(context);

    await _ensureActiveConversation();

    final userMsg = ChatMessage(
      text:
          l10n?.aiAgentZhekeZhosparDesc ??
          '📋 Создай мне Жеке Жоспар (персональный план поступления)',
      isUser: true,
      time: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _startThinkingSteps(isZheke: true);
    _scrollToBottom();

    unawaited(_historyService.addMessage(userMsg));

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
        _stopThinkingSteps();
        final aiMsg = ChatMessage(
          text: response,
          isUser: false,
          time: DateTime.now(),
        );
        setState(() {
          _isTyping = false;
          _messages.add(aiMsg);
        });
        unawaited(_historyService.addMessage(aiMsg));
        _scrollToBottom();
      }
    } on OutOfTokensException catch (e) {
      if (mounted) {
        _stopThinkingSteps();
        final errMsg = ChatMessage(
          text: e.message,
          isUser: false,
          time: DateTime.now(),
        );
        setState(() {
          _isTyping = false;
          _messages.add(errMsg);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        _stopThinkingSteps();
        final errMsg = ChatMessage(
          text: l10n?.aiError ?? 'Произошла ошибка. Попробуйте позже.',
          isUser: false,
          time: DateTime.now(),
        );
        setState(() {
          _isTyping = false;
          _messages.add(errMsg);
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
          duration: const Duration(milliseconds: 200),
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
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildHistoryDrawer(isDark),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip:
              AppLocalizations.of(context)?.aiChatHistory ?? 'История чатов',
        ),
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
                      AppLocalizations.of(context)?.aiAgentStatusOnline ??
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
          // New chat button
          IconButton(
            icon: Icon(
              Icons.edit_square,
              color: isDark ? Colors.white : AppColors.textPrimary,
              size: 22,
            ),
            onPressed: () {
              _historyService.createConversation();
              setState(() => _messages.clear());
              _fadeController.reset();
              _fadeController.forward();
            },
            tooltip: AppLocalizations.of(context)?.aiNewChat ?? 'Новый чат',
          ),
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
  //  HISTORY DRAWER
  // ═══════════════════════════════════════════
  Widget _buildHistoryDrawer(bool isDark) {
    final l10n = AppLocalizations.of(context);

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const AILogoIcon(size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n?.aiChatHistory ?? 'История чатов',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // New chat button in drawer
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 24),
                    color: const Color(0xFF6366F1),
                    onPressed: _createNewChat,
                    tooltip: l10n?.aiNewChat ?? 'Новый чат',
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.border,
            ),
            // Conversation list
            Expanded(
              child: ValueListenableBuilder<List<ChatConversation>>(
                valueListenable: _historyService.conversations,
                builder: (context, convs, _) {
                  if (convs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: isDark ? Colors.white24 : AppColors.textHint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n?.aiNoChats ?? 'Нет чатов',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.textHint,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by time
                  final grouped = _groupConversations(convs);
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final entry = grouped[index];
                      if (entry is String) {
                        // Section header
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                          child: Text(
                            entry,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.textHint,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }
                      final conv = entry as ChatConversation;
                      final isActive =
                          conv.id == _historyService.activeConversationId.value;
                      return _buildConversationTile(conv, isActive, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    ChatConversation conv,
    bool isActive,
    bool isDark,
  ) {
    final title = conv.title.isNotEmpty
        ? conv.title
        : (AppLocalizations.of(context)?.aiNewChat ?? 'Новый чат');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive
            ? (isDark
                  ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                  : const Color(0xFF6366F1).withValues(alpha: 0.08))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _switchConversation(conv.id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color: isActive
                      ? const Color(0xFF6366F1)
                      : (isDark ? Colors.white54 : AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? (isDark ? Colors.white : AppColors.textPrimary)
                          : (isDark ? Colors.white70 : AppColors.textSecondary),
                    ),
                  ),
                ),
                // Delete
                InkWell(
                  onTap: () => _confirmDeleteConversation(conv.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: isDark ? Colors.white24 : AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteConversation(String id) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.aiDeleteChat ?? 'Удалить чат'),
        content: Text(l10n?.aiDeleteChatConfirm ?? 'Удалить этот чат?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.commonCancel ?? 'Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _historyService.deleteConversation(id);
              await _loadActiveConversation();
            },
            child: Text(
              l10n?.aiClearDialogConfirm ?? 'Удалить',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Group conversations by: Today, Yesterday, Last 7 days, Older
  List<dynamic> _groupConversations(List<ChatConversation> convs) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final week = today.subtract(const Duration(days: 7));

    final result = <dynamic>[];
    final todayList = <ChatConversation>[];
    final yesterdayList = <ChatConversation>[];
    final weekList = <ChatConversation>[];
    final olderList = <ChatConversation>[];

    for (final c in convs) {
      final d = DateTime(c.updatedAt.year, c.updatedAt.month, c.updatedAt.day);
      if (!d.isBefore(today)) {
        todayList.add(c);
      } else if (!d.isBefore(yesterday)) {
        yesterdayList.add(c);
      } else if (!d.isBefore(week)) {
        weekList.add(c);
      } else {
        olderList.add(c);
      }
    }

    if (todayList.isNotEmpty) {
      result.add(l10n?.aiToday ?? 'Сегодня');
      result.addAll(todayList);
    }
    if (yesterdayList.isNotEmpty) {
      result.add(l10n?.aiYesterday ?? 'Вчера');
      result.addAll(yesterdayList);
    }
    if (weekList.isNotEmpty) {
      result.add(l10n?.aiPrevious7Days ?? 'Последние 7 дней');
      result.addAll(weekList);
    }
    if (olderList.isNotEmpty) {
      result.add(l10n?.aiOlder ?? 'Ранее');
      result.addAll(olderList);
    }

    return result;
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
              child: FilledButton(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnboardingWizardScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    _sendMessage(
                      text:
                          l10n?.wizardProfileUpdated ??
                          'Мой профиль обновлён! Покажи мне подходящие вузы.',
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n?.wizardProfileButton ?? '🚀 Заполни профиль за 2 мин',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
                  l10n?.successStoriesChip ?? '📖 Истории успеха',
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.aiAgentZhekeZhosparTitle ??
                    'Жеке Жоспар',
                style: const TextStyle(
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
      addRepaintBoundaries: true,
      cacheExtent: 200,
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator(isDark);
        }
        return RepaintBoundary(
          child: _buildMessageBubble(_messages[index], isDark),
        );
      },
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return _AIThinkingStream(
      isDark: isDark,
      currentStep: _thinkingStep,
      isZhekeZhospar: _isZhekeZhospar,
      query: _currentQuery,
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
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
            onPressed: () async {
              setState(() => _messages.clear());
              final activeId = _historyService.activeConversationId.value;
              if (activeId != null) {
                await _historyService.setMessages(activeId, []);
              }
              if (ctx.mounted) Navigator.pop(ctx);
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
//  AI THINKING STREAM (контекстный, как ChatGPT/Gemini)
// ═══════════════════════════════════════════
class _AIThinkingStream extends StatelessWidget {
  final bool isDark;
  final int currentStep;
  final bool isZhekeZhospar;
  final String query;

  const _AIThinkingStream({
    required this.isDark,
    required this.currentStep,
    this.isZhekeZhospar = false,
    this.query = '',
  });

  List<String> _getSteps(BuildContext context) {
    if (isZhekeZhospar) {
      return [
        'Анализирую профиль абитуриента',
        'Подбираю подходящие вузы',
        'Рассчитываю шансы на грант',
        'Составляю план поступления',
        'Оформляю персональный жоспар',
      ];
    }

    final lower = query.toLowerCase();

    // Простые запросы — 2 шага
    if (_isGreeting(lower)) {
      return ['Обрабатываю запрос', 'Генерирую ответ'];
    }

    // Вопросы про конкретный вуз
    if (_isUniversityQuery(lower)) {
      return [
        'Анализирую запрос',
        'Ищу информацию по вузам',
        'Сопоставляю с вашим профилем',
        'Формирую рекомендацию',
      ];
    }

    // Вопросы про грант / шансы / ЕНТ
    if (_isGrantQuery(lower)) {
      return [
        'Анализирую ваши баллы',
        'Сравниваю с проходными баллами',
        'Рассчитываю вероятность',
        'Формирую оценку шансов',
      ];
    }

    // Вопросы про специальность / профессию
    if (_isSpecialtyQuery(lower)) {
      return [
        'Анализирую запрос',
        'Ищу подходящие специальности',
        'Подбираю вузы',
        'Формирую рекомендацию',
      ];
    }

    // По умолчанию
    return [
      'Анализирую запрос',
      'Ищу релевантную информацию',
      'Формирую ответ',
      'Готовлю рекомендацию',
    ];
  }

  bool _isGreeting(String q) {
    const words = [
      'привет',
      'салем',
      'здравствуй',
      'хай',
      'hi',
      'hello',
      'кто ты',
      'что умеешь',
      'как дела',
      'спасибо',
    ];
    return q.length < 15 || words.any((w) => q.contains(w));
  }

  bool _isUniversityQuery(String q) {
    const words = [
      'вуз',
      'универ',
      'университет',
      'нарх',
      'кбту',
      'ену',
      'назарбаев',
      'казну',
      'aitu',
      'каз',
      'поступ',
    ];
    return words.any((w) => q.contains(w));
  }

  bool _isGrantQuery(String q) {
    const words = [
      'грант',
      'шанс',
      'балл',
      'ент',
      'ент ',
      'проходн',
      'стипенд',
      'квота',
      'скольк',
    ];
    return words.any((w) => q.contains(w));
  }

  bool _isSpecialtyQuery(String q) {
    const words = [
      'специальность',
      'профес',
      'направлен',
      'факультет',
      'it',
      'медицин',
      'юрист',
      'програм',
      'инженер',
    ];
    return words.any((w) => q.contains(w));
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i <= currentStep && i < steps.length; i++)
                    _ThinkingStepRow(
                      key: ValueKey('step_$i'),
                      text: steps[i],
                      isCompleted: i < currentStep,
                      isActive: i == currentStep,
                      isDark: isDark,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual row in the AI thinking stream (без эмодзи, как ChatGPT).
class _ThinkingStepRow extends StatefulWidget {
  final String text;
  final bool isCompleted;
  final bool isActive;
  final bool isDark;

  const _ThinkingStepRow({
    super.key,
    required this.text,
    required this.isCompleted,
    required this.isActive,
    required this.isDark,
  });

  @override
  State<_ThinkingStepRow> createState() => _ThinkingStepRowState();
}

class _ThinkingStepRowState extends State<_ThinkingStepRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isCompleted)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Color(0xFF10B981),
                )
              else if (widget.isActive)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: const Color(0xFF6366F1),
                  ),
                )
              else
                const SizedBox(width: 14),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.isActive ? '${widget.text}...' : widget.text,
                  style: TextStyle(
                    color: widget.isCompleted
                        ? (widget.isDark ? Colors.white38 : AppColors.textHint)
                        : (widget.isDark
                              ? Colors.white70
                              : AppColors.textSecondary),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
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
