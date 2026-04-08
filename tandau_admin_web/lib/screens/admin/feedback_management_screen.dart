import 'package:flutter/material.dart';
import '../../services/feedback_service.dart';
import '../../models/app_feedback.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() => _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  final FeedbackService _feedbackService = FeedbackService();

  String _formatDate(DateTime dt) {
    return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  }

  Color _getStatusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.new_:
        return Colors.blueAccent;
      case FeedbackStatus.inProgress:
        return Colors.orangeAccent;
      case FeedbackStatus.resolved:
        return AppColors.success;
      case FeedbackStatus.rejected:
        return AppColors.error;
    }
  }

  String _getStatusText(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.new_:
        return 'НОВАЯ';
      case FeedbackStatus.inProgress:
        return 'В РАБОТЕ';
      case FeedbackStatus.resolved:
        return 'РЕШЕНО';
      case FeedbackStatus.rejected:
        return 'ОТКЛОНЕНО';
    }
  }

  String _getTypeText(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return '🐞 Ошибка';
      case FeedbackType.suggestion:
        return '💡 Предложение';
      case FeedbackType.other:
        return '💬 Другое';
    }
  }

  Future<void> _updateStatus(AppFeedback feedback) async {
    FeedbackStatus? currentStatus = feedback.status;
    final TextEditingController replyController = TextEditingController(text: feedback.adminReply ?? '');

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: const Text('Обновить статус', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Новый статус:', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                      ),
                      child: DropdownButton<FeedbackStatus>(
                        value: currentStatus,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: Colors.white),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: FeedbackStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_getStatusText(status)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => currentStatus = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ответ пользователю:', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: replyController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Введите ответ...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.black12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ОТМЕНА', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _feedbackService.updateFeedbackStatus(
                      feedback.id,
                      currentStatus!,
                      adminReply: replyController.text.trim().isEmpty ? null : replyController.text.trim(),
                    );
                    if (!context.mounted) return;
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Статус обновлён'), backgroundColor: AppColors.success),
                      );
                    }
                  },
                  child: const Text('СОХРАНИТЬ', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: const [
              Icon(Icons.feedback_rounded, color: AppColors.primary, size: 28),
              SizedBox(width: 16),
              Text(
                'Управление обращениями',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AppFeedback>>(
            stream: _feedbackService.getFeedbacksStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Нет обращений', style: TextStyle(color: Colors.grey, fontSize: 18)),
                );
              }

              final feedbacks = snapshot.data!;

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: feedbacks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final feedback = feedbacks[index];
                  final isNew = feedback.status == FeedbackStatus.new_;
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isNew ? AppColors.primary.withValues(alpha: 0.5) : Colors.white10,
                        width: isNew ? 1.5 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white10,
                                    child: const Icon(Icons.person, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(feedback.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text(_formatDate(feedback.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(_getTypeText(feedback.type), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(feedback.status).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _getStatusColor(feedback.status).withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      _getStatusText(feedback.status),
                                      style: TextStyle(color: _getStatusColor(feedback.status), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                                    tooltip: 'Изменить статус',
                                    onPressed: () => _updateStatus(feedback),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(feedback.message, style: const TextStyle(color: Colors.white, fontSize: 15)),
                          ),
                          if (feedback.adminReply != null && feedback.adminReply!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ваш ответ:', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(feedback.adminReply!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
