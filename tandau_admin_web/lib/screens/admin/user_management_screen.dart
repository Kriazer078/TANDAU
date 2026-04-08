import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/audit_log_service.dart';
import '../../theme/app_colors.dart';

/// SECURITY: This screen must only be accessible by admins.
/// Guard checks are performed both at build-time and before every mutation.

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ── Pagination state ──
  static const int _pageSize = 20;
  List<UserModel> _users = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _totalCount = 0;

  // ── Filters ──
  String _searchQuery = '';
  String _roleFilter = 'all'; // 'all', 'user', 'admin'
  String _sortBy = 'createdAt'; // 'createdAt', 'name'

  // ── Debounce ──
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _getTotalCount();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════
  //  DATA LOADING
  // ═══════════════════════════════════════════

  /// Load users page. If loadMore=true, appends to existing list.
  Future<void> _loadUsers({bool loadMore = false}) async {
    if (_isLoading || (_isLoadingMore && loadMore)) return;
    if (loadMore && !_hasMore) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _users = [];
        _lastDoc = null;
        _hasMore = true;
      }
    });

    try {
      // Build Firestore query with ordering + limit
      Query<Map<String, dynamic>> query = _firestore.collection('users');

      if (_sortBy == 'createdAt') {
        query = query.orderBy('createdAt', descending: true);
      } else {
        query = query.orderBy('name');
      }

      query = query.limit(_pageSize);

      if (loadMore && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get().timeout(const Duration(seconds: 15));

      final List<UserModel> fetched = [];
      for (final doc in snapshot.docs) {
        try {
          fetched.add(UserModel.fromDocument(doc));
        } catch (e) {
          debugPrint('⚠️ Error parsing user ${doc.id}: $e');
        }
      }

      // Apply client-side filters (role & search)
      List<UserModel> filtered = _applyFilters(fetched);

      if (mounted) {
        setState(() {
          if (loadMore) {
            _users.addAll(filtered);
          } else {
            _users = filtered;
          }

          if (snapshot.docs.isNotEmpty) {
            _lastDoc = snapshot.docs.last;
          }
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }

      // If after filtering we have too few items and there's more, auto-load
      if (filtered.length < 5 && _hasMore && mounted) {
        _loadUsers(loadMore: true);
      }
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get total user count for stats header
  Future<void> _getTotalCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .count()
          .get()
          .timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _totalCount = snapshot.count ?? 0;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error getting total count: $e');
    }
  }

  /// Apply role & search filters on already-fetched documents
  List<UserModel> _applyFilters(List<UserModel> users) {
    List<UserModel> result = users;

    // Filter by role
    if (_roleFilter != 'all') {
      result = result.where((u) => u.role == _roleFilter).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((u) {
        return u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  /// Scroll listener for infinite scroll
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadUsers(loadMore: true);
    }
  }

  /// Debounced search handler
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value);
      _loadUsers(); // Reload from scratch with new filter
    });
  }

  // ═══════════════════════════════════════════
  //  MUTATIONS
  // ═══════════════════════════════════════════

  // ── Change user role ──
  Future<void> _changeRole(UserModel user, String newRole) async {
    // SECURITY: Double-check admin before mutation
    if (!AuthService().isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Доступ запрещён'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // SECURITY: Prevent self-modification
    if (AuthService().currentUser.value?.uid == user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Нельзя менять свою роль'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // SECURITY: Validate role value
    if (newRole != 'admin' && newRole != 'user' && newRole != 'moderator') {
      debugPrint('❌ Invalid role value: $newRole');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'role': newRole,
      });
      // 📋 Audit log
      AuditLogService().log(
        action: AuditLogService.actionChangeRole,
        targetUid: user.uid,
        targetName: user.name,
        details: '${user.role} → $newRole',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${user.name} → ${newRole == 'admin' ? 'Админ' : newRole == 'moderator' ? 'Модератор' : 'Пользователь'}',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers(); // Refresh list
      }
    } catch (e) {
      debugPrint('❌ Error changing role: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Delete user data from Firestore ──
  Future<void> _deleteUserData(UserModel user) async {
    // SECURITY: Double-check admin before destructive operation
    if (!AuthService().isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Доступ запрещён'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // SECURITY: Never allow deleting own account via this panel
    if (AuthService().currentUser.value?.uid == user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Нельзя удалить свой аккаунт через админ-панель'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Collect all documents to delete
      final List<DocumentReference> docsToDelete = [];

      // Reviews
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .get();
      docsToDelete.addAll(reviewsSnapshot.docs.map((d) => d.reference));

      // Likes
      final likesSnapshot = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: user.uid)
          .get();
      docsToDelete.addAll(likesSnapshot.docs.map((d) => d.reference));

      // Notifications subcollection
      final notifSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();
      docsToDelete.addAll(notifSnapshot.docs.map((d) => d.reference));

      // User document itself
      docsToDelete.add(_firestore.collection('users').doc(user.uid));

      // SAFETY: Split into batches of 500 (Firestore limit)
      const int batchLimit = 499; // Leave room for safety
      for (int i = 0; i < docsToDelete.length; i += batchLimit) {
        final batch = _firestore.batch();
        final chunk = docsToDelete.skip(i).take(batchLimit);
        for (final ref in chunk) {
          batch.delete(ref);
        }
        await batch.commit();
      }

      // 📋 Audit log
      AuditLogService().log(
        action: AuditLogService.actionDeleteUser,
        targetUid: user.uid,
        targetName: user.name,
        details: 'Удалены все данные пользователя',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Данные пользователя ${user.name} удалены'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers(); // Refresh
        _getTotalCount();
      }
    } catch (e) {
      debugPrint('❌ Error deleting user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Ban / Unban user ──
  Future<void> _toggleBan(UserModel user, {String? reason}) async {
    // SECURITY checks
    if (!AuthService().isAdmin) return;
    if (AuthService().currentUser.value?.uid == user.uid) return;

    try {
      final bool banning = !user.banned;
      await _firestore.collection('users').doc(user.uid).update({
        'banned': banning,
        'banReason': banning ? (reason ?? 'Нарушение правил') : null,
      });
      // 📋 Audit log
      AuditLogService().log(
        action: banning
            ? AuditLogService.actionBanUser
            : AuditLogService.actionUnbanUser,
        targetUid: user.uid,
        targetName: user.name,
        details: banning ? 'Причина: ${reason ?? 'Нарушение правил'}' : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              banning
                  ? '🚫 ${user.name} заблокирован'
                  : '✅ ${user.name} разблокирован',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: banning ? Colors.orange : Colors.green,
          ),
        );
        _loadUsers(); // Refresh
      }
    } catch (e) {
      debugPrint('❌ Error toggling ban: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ═══════════════════════════════════════════
  //  DIALOGS
  // ═══════════════════════════════════════════

  // ── Show ban dialog with reason input ──
  void _showBanDialog(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Icon(
              user.banned ? Icons.lock_open_rounded : Icons.block_rounded,
              color: user.banned ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                user.banned
                    ? 'Разблокировать ${user.name}?'
                    : 'Заблокировать ${user.name}?',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.banned) ...[
              Text(
                'Текущая причина: ${user.banReason ?? "Не указана"}',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Пользователь сможет снова войти в приложение.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
            ] else ...[
              Text(
                'Пользователь будет автоматически разлогинен и не сможет войти.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Причина блокировки...',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _toggleBan(
                user,
                reason: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : null,
              );
            },
            icon: Icon(
              user.banned ? Icons.lock_open_rounded : Icons.block_rounded,
              size: 18,
            ),
            label: Text(user.banned ? 'Разблокировать' : 'Заблокировать'),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.banned ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Show user actions ──
  void _showUserActions(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelf = AuthService().currentUser.value?.uid == user.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User info header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _avatarColor(
                        user.name,
                      ).withValues(alpha: 0.15),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: _avatarColor(user.name),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelf) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Вы',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (user.banned) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'БАН',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SelectableText(
                            user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            'ID: ${user.uid}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Ban reason banner
              if (user.banned && user.banReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.gavel_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Причина: ${user.banReason}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),

              // Actions
              if (!isSelf) ...[
                if (AuthService().isAdmin) ...[
                  // Ban / Unban
                  ListTile(
                    leading: Icon(
                      user.banned ? Icons.lock_open_rounded : Icons.block_rounded,
                      color: user.banned ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      user.banned ? 'Разблокировать' : 'Заблокировать',
                      style: TextStyle(
                        color: user.banned ? Colors.green : Colors.orange,
                      ),
                    ),
                    subtitle: Text(
                      user.banned
                          ? 'Снять блокировку, пользователь сможет войти'
                          : 'Пользователь будет разлогинен и не сможет войти',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showBanDialog(user);
                    },
                  ),

                  // Change role — admin only
                  ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.purple,
                    ),
                    title: const Text('Изменить роль'),
                    subtitle: Text(
                      'Пользователь / Модератор / Админ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showRoleSelectionDialog(user);
                    },
                  ),

                  // Delete user data — admin only
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Удалить данные пользователя',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: Text(
                      'Удалит профиль, отзывы, лайки и уведомления',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.withValues(alpha: 0.6),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showDeleteConfirmation(user);
                    },
                  ),
                ],
              ] else ...[
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Вы не можете изменять свой собственный аккаунт через эту панель',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                ),
              ],

              // User details
              ExpansionTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
                title: const Text('Подробная информация'),
                children: [
                  _buildDetailRow('UID', user.uid, isDark),
                  _buildDetailRow('Имя', user.name, isDark),
                  _buildDetailRow('Email', user.email, isDark),
                  _buildDetailRow('Роль', user.role, isDark),
                  _buildDetailRow(
                    'Статус',
                    user.banned ? '🚫 Заблокирован' : '✅ Активен',
                    isDark,
                  ),
                  if (user.banned && user.banReason != null)
                    _buildDetailRow('Причина', user.banReason!, isDark),
                  _buildDetailRow('Город', user.city ?? '—', isDark),
                  _buildDetailRow('ЕНТ', '${user.untScore ?? '—'}', isDark),
                  _buildDetailRow(
                    'Регистрация',
                    _formatDate(user.createdAt),
                    isDark,
                  ),
                  _buildDetailRow(
                    'Избранных',
                    '${user.favoriteUniversities.length}',
                    isDark,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleSelectionDialog(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Colors.purple),
            SizedBox(width: 12),
            Text('Изменить роль'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите новую роль для ${user.name}:',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildRoleOption(
              ctx,
              user,
              'user',
              'Пользователь',
              Icons.person_rounded,
              Colors.grey,
              isDark,
            ),
            const SizedBox(height: 8),
            _buildRoleOption(
              ctx,
              user,
              'moderator',
              'Модератор',
              Icons.shield_rounded,
              Colors.blue,
              isDark,
            ),
            const SizedBox(height: 8),
            _buildRoleOption(
              ctx,
              user,
              'admin',
              'Администратор',
              Icons.star_rounded,
              Colors.orange,
              isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext ctx,
    UserModel user,
    String roleValue,
    String roleName,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final bool isSelected = user.role == roleValue;
    return InkWell(
      onTap: isSelected
          ? null
          : () {
              Navigator.pop(ctx);
              _changeRole(user, roleValue);
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? Colors.white24 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : (isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(width: 12),
            Text(
              roleName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? color
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Удалить пользователя?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user.name} (${user.email})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Будут удалены:\n'
              '• Профиль пользователя\n'
              '• Все отзывы\n'
              '• Все лайки\n'
              '• Все уведомления\n\n'
              '⚠️ Это действие необратимо!',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteUserData(user);
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Удалить всё'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // SECURITY: Guard — only admin/moderator can see this screen
    if (!AuthService().hasAdminAccess) {
      return const Center(child: Text('❌ У вас нет прав доступа'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Toolbar row with search + actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Поиск по имени или email...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  _loadUsers();
                  _getTotalCount();
                },
                tooltip: 'Обновить',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort_rounded),
                onSelected: (value) {
                  setState(() => _sortBy = value);
                  _loadUsers();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'createdAt',
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: _sortBy == 'createdAt'
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text('По дате'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_by_alpha,
                          size: 18,
                          color: _sortBy == 'name'
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text('По имени'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Role filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Все', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Пользователи', 'user', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Модераторы', 'moderator', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Админы', 'admin', isDark),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Users list
        Expanded(
          child: _isLoading
              ? _buildShimmerLoading(isDark)
              : _users.isEmpty
              ? _buildEmptyState(isDark)
              : _buildUsersList(isDark),
        ),
      ],
    );
  }

  // ── User list with pagination ──
  Widget _buildUsersList(bool isDark) {
    // Count admins and moderators in loaded users for stats
    final int adminsCount = _users.where((u) => u.role == 'admin').length;
    final int modsCount = _users.where((u) => u.role == 'moderator').length;

    return Column(
      children: [
        // Stats header (uses _totalCount from Firestore .count())
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('👥', 'Всего', '$_totalCount', isDark),
              _buildStatItem('⭐', 'Админы', '$adminsCount', isDark),
              _buildStatItem('🛡️', 'Модеры', '$modsCount', isDark),
              _buildStatItem('📄', 'Загружено', '${_users.length}', isDark),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadUsers();
              await _getTotalCount();
            },
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _users.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _users.length) {
                  // "Load more" indicator at the bottom
                  return _buildLoadMoreIndicator(isDark);
                }
                return _buildUserCard(_users[index], isDark);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Load more indicator ──
  Widget _buildLoadMoreIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Загрузка...',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: () => _loadUsers(loadMore: true),
              child: Text(
                'Загрузить ещё',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  // ── Empty state ──
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Пользователей не найдено',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: const Text('Сбросить поиск'),
            ),
          ],
        ],
      ),
    );
  }

  // ── Shimmer loading ──
  Widget _buildShimmerLoading(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade300,
      highlightColor: isDark ? const Color(0xFF3A3A50) : Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 8,
        itemBuilder: (context, _) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 22, backgroundColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 180,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter chips ──
  Widget _buildFilterChip(String label, String value, bool isDark) {
    final bool isSelected = _roleFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _roleFilter = value);
        _loadUsers(); // Reload with new filter
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? AppColors.primary
                : isDark
                ? Colors.white54
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value, bool isDark) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white38 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user, bool isDark) {
    final bool isAdmin = user.role == 'admin';
    final bool isModerator = user.role == 'moderator';
    final bool isSelf = AuthService().currentUser.value?.uid == user.uid;

    return InkWell(
      onTap: () => _showUserActions(user),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelf
                ? AppColors.primary.withValues(alpha: 0.3)
                : user.banned
                ? Colors.red.withValues(alpha: 0.3)
                : isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _avatarColor(
                    user.name,
                  ).withValues(alpha: 0.15),
                  backgroundImage:
                      user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: _avatarColor(user.name),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                // Admin / Moderator badge
                if (isAdmin || isModerator)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAdmin ? Icons.star_rounded : Icons.shield_rounded,
                        size: 12,
                        color: isAdmin ? Colors.orange : Colors.blue,
                      ),
                    ),
                  ),
                // Ban badge
                if (user.banned)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        size: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(Вы)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Role chip + date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: user.banned
                        ? Colors.red.withValues(alpha: 0.1)
                        : isAdmin
                        ? Colors.orange.withValues(alpha: 0.1)
                        : isModerator
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.banned
                        ? '🚫 БАН'
                        : isAdmin
                        ? 'Админ'
                        : isModerator
                        ? 'Модератор'
                        : 'User',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: user.banned
                          ? Colors.red
                          : isAdmin
                          ? Colors.orange
                          : isModerator
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(user.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white24 : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? Colors.white24 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];
    final int hash = name.codeUnits.fold<int>(0, (prev, c) => prev + c);
    return colors[hash % colors.length];
  }
}
