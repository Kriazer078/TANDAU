import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/audit_log_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

/// Admin screen to view all admin action logs with filtering and pagination.
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final AuditLogService _auditService = AuditLogService();
  final ScrollController _scrollController = ScrollController();

  // ── Pagination state ──
  List<AuditLogEntry> _logs = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  // ── Filter ──
  String? _actionFilter;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs({bool loadMore = false}) async {
    if (_isLoading || (_isLoadingMore && loadMore)) return;
    if (loadMore && !_hasMore) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _logs = [];
        _lastDoc = null;
        _hasMore = true;
      }
    });

    try {
      final page = await _auditService.getLogs(
        limit: 20,
        startAfter: loadMore ? _lastDoc : null,
        actionFilter: _actionFilter,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _logs.addAll(page.entries);
          } else {
            _logs = page.entries;
          }
          _lastDoc = page.lastDoc;
          _hasMore = page.hasMore;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading audit logs: $e');
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadLogs(loadMore: true);
    }
  }

  // ── Action icon & color ──
  IconData _actionIcon(String action) {
    switch (action) {
      case AuditLogService.actionBanUser:
        return Icons.block_rounded;
      case AuditLogService.actionUnbanUser:
        return Icons.lock_open_rounded;
      case AuditLogService.actionChangeRole:
        return Icons.admin_panel_settings_rounded;
      case AuditLogService.actionDeleteUser:
        return Icons.person_remove_rounded;
      case AuditLogService.actionDeleteReview:
        return Icons.delete_rounded;
      case AuditLogService.actionSendNotification:
        return Icons.send_rounded;
      case AuditLogService.actionBroadcastNotification:
        return Icons.campaign_rounded;
      case AuditLogService.actionUpdateUniversity:
        return Icons.edit_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case AuditLogService.actionBanUser:
        return Colors.red;
      case AuditLogService.actionUnbanUser:
        return Colors.green;
      case AuditLogService.actionChangeRole:
        return Colors.purple;
      case AuditLogService.actionDeleteUser:
        return Colors.red.shade700;
      case AuditLogService.actionDeleteReview:
        return Colors.orange;
      case AuditLogService.actionSendNotification:
        return Colors.blue;
      case AuditLogService.actionBroadcastNotification:
        return Colors.teal;
      case AuditLogService.actionUpdateUniversity:
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final String day = dt.day.toString().padLeft(2, '0');
    final String month = dt.month.toString().padLeft(2, '0');
    final String hour = dt.hour.toString().padLeft(2, '0');
    final String minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.${dt.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService().isAdmin) {
      return const Center(child: Text('❌ У вас нет прав администратора'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ── Filter chips ──
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildFilterChip('Все', null, isDark),
              const SizedBox(width: 8),
              ...AuditLogService.allActions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    AuditLogService.actionLabel(action),
                    action,
                    isDark,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Logs list ──
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: () => _loadLogs(),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _logs.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _logs.length) {
                        return _buildLoadMore(isDark);
                      }
                      return _buildLogCard(_logs[index], isDark);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? value, bool isDark) {
    final bool isSelected = _actionFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _actionFilter = value);
        _loadLogs();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            fontSize: 12,
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

  Widget _buildLogCard(AuditLogEntry entry, bool isDark) {
    final Color color = _actionColor(entry.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_actionIcon(entry.action), color: color, size: 20),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action label
                Text(
                  AuditLogService.actionLabel(entry.action),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Target
                if (entry.targetName != null)
                  Text(
                    '👤 ${entry.targetName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),

                // Details
                if (entry.details != null && entry.details!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.details!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (entry.diffs != null && entry.diffs!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: entry.diffs!.entries.map((e) {
                        if (e.value is Map) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${e.key}: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: '${e.value['old']} ', style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red.shade300, fontSize: 11)),
                                        const TextSpan(text: '→ ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                        TextSpan(text: '${e.value['new']}', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.green, fontSize: 11)),
                                      ]
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('${e.key}: ${e.value}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87)),
                          );
                        }
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                // Admin + timestamp
                Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 12,
                      color: isDark ? Colors.white24 : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        entry.adminEmail,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white24 : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTimestamp(entry.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white24 : Colors.grey,
                      ),
                    ),
                    if (entry.ipAddress != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• IP: ${entry.ipAddress}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white24 : Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              Icons.history_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Логов пока нет',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Действия админов будут записываться сюда',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMore(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            )
          : GestureDetector(
              onTap: () => _loadLogs(loadMore: true),
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
}
