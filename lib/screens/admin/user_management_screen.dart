import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
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

  String _searchQuery = '';
  String _roleFilter = 'all'; // 'all', 'user', 'admin'
  String _sortBy = 'createdAt'; // 'createdAt', 'name'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Get users stream ──
  Stream<List<UserModel>> _getUsersStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('users');

    if (_sortBy == 'createdAt') {
      query = query.orderBy('createdAt', descending: true);
    } else {
      query = query.orderBy('name');
    }

    return query.snapshots().map((snapshot) {
      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .toList();

      // Filter by role
      if (_roleFilter != 'all') {
        users = users.where((u) => u.role == _roleFilter).toList();
      }

      // Filter by search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        users = users.where((u) {
          return u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q);
        }).toList();
      }

      return users;
    });
  }

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
    if (newRole != 'admin' && newRole != 'user') {
      debugPrint('❌ Invalid role value: $newRole');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'role': newRole,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${user.name} → ${newRole == 'admin' ? 'Админ' : 'Пользователь'}',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.green,
          ),
        );
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
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.textSecondary,
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

                // Toggle role
                ListTile(
                  leading: Icon(
                    user.role == 'admin'
                        ? Icons.person_rounded
                        : Icons.admin_panel_settings_rounded,
                    color: user.role == 'admin' ? Colors.orange : Colors.purple,
                  ),
                  title: Text(
                    user.role == 'admin'
                        ? 'Снять роль админа'
                        : 'Назначить админом',
                  ),
                  subtitle: Text(
                    user.role == 'admin'
                        ? 'Сделать обычным пользователем'
                        : 'Дать права администратора',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRoleConfirmation(
                      user,
                      user.role == 'admin' ? 'user' : 'admin',
                    );
                  },
                ),

                // Delete user data
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

  void _showRoleConfirmation(UserModel user, String newRole) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPromoting = newRole == 'admin';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Icon(
              isPromoting
                  ? Icons.admin_panel_settings_rounded
                  : Icons.person_rounded,
              color: isPromoting ? Colors.purple : Colors.orange,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                isPromoting ? 'Назначить админом?' : 'Снять роль админа?',
              ),
            ),
          ],
        ),
        content: Text(
          isPromoting
              ? '${user.name} получит доступ к админ-панели и сможет модерировать отзывы, отправлять уведомления и управлять пользователями.'
              : '${user.name} потеряет доступ к админ-панели и все административные права.',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textPrimary,
          ),
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _changeRole(user, newRole);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPromoting ? Colors.purple : Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isPromoting ? 'Назначить' : 'Снять'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    // SECURITY: Guard — if somehow opened by non-admin, block access
    if (!AuthService().isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Доступ запрещён')),
        body: const Center(child: Text('❌ У вас нет прав администратора')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Пользователи'),
        elevation: 0,
        actions: [
          // Sort
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
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
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Поиск по имени или email...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
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

          // Role filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Все', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Пользователи', 'user', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Админы', 'admin', isDark),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Users list
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text('Ошибка: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
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
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Stats header
                final int adminsCount = users
                    .where((u) => u.role == 'admin')
                    .length;

                return Column(
                  children: [
                    // Stats
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            '👥',
                            'Всего',
                            '${users.length}',
                            isDark,
                          ),
                          _buildStatItem(
                            '🛡️',
                            'Админы',
                            '$adminsCount',
                            isDark,
                          ),
                          _buildStatItem(
                            '👤',
                            'Пользователи',
                            '${users.length - adminsCount}',
                            isDark,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(users[index], isDark);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final bool isSelected = _roleFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _roleFilter = value),
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
                // Admin badge
                if (isAdmin)
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
                        Icons.shield_rounded,
                        size: 12,
                        color: Colors.purple,
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
                        ? Colors.purple.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.banned
                        ? '🚫 БАН'
                        : isAdmin
                        ? 'Админ'
                        : 'User',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: user.banned
                          ? Colors.red
                          : isAdmin
                          ? Colors.purple
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
