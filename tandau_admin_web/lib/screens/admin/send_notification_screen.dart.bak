import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/notification.dart';
import '../../theme/app_colors.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  Timer? _debounce;

  UserModel? _selectedUser;
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  bool _isSending = false;
  bool _broadcastMode = false;
  NotificationType _selectedType = NotificationType.news;

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _applyTemplate({required String title, required String message, required NotificationType type}) {
    setState(() {
      _titleController.text = title;
      _messageController.text = message;
      _selectedType = type;
      if (type == NotificationType.alert) {
        _linkController.text = 'https://play.google.com/store/apps/details?id=kz.tandau.app'; // example
      } else {
        _linkController.clear();
      }
    });
  }

  void _searchUsers(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    if (mounted) setState(() => _isSearching = true);
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _adminService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _send() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      _showSnackBar('Заполните заголовок и сообщение', isError: true);
      return;
    }

    if (!_broadcastMode && _selectedUser == null) {
      _showSnackBar('Выберите пользователя', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      final data = _linkController.text.isNotEmpty 
          ? {'actionUrl': _linkController.text} 
          : null;

      if (_broadcastMode) {
        final count = await _adminService.broadcastNotification(
          title: _titleController.text,
          message: _messageController.text,
          type: _selectedType,
          data: data,
        );
        _showSnackBar('Уведомление отправлено $count пользователям');
      } else {
        await _adminService.sendNotification(
          targetUserId: _selectedUser!.uid,
          title: _titleController.text,
          message: _messageController.text,
          type: _selectedType,
          data: data,
        );
        _showSnackBar('Уведомление отправлено для ${_selectedUser!.name}');
      }

      if (mounted) {
        _titleController.clear();
        _messageController.clear();
        _linkController.clear();
        setState(() {
          _selectedUser = null;
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _showSnackBar('Ошибка: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SECURITY: Guard — block non-admin access
    if (!AuthService().isAdmin) {
      return const Center(child: Text('❌ У вас нет прав администратора'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode Toggle
          SwitchListTile(
            title: const Text('Отправить ВСЕМ пользователям'),
            subtitle: const Text('Создаст уведомление в приложении для всех'),
            value: _broadcastMode,
            onChanged: (val) {
              setState(() {
                _broadcastMode = val;
                if (val) _selectedUser = null;
              });
            },
            activeThumbColor: AppColors.primary,
          ),
          const Divider(),
          const SizedBox(height: 16),

          if (!_broadcastMode) ...[
            const Text(
              'Кому отправить?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_selectedUser != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        _selectedUser!.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedUser!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _selectedUser!.email,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedUser = null),
                    ),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск по имени или email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _searchUsers,
              ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_searchController.text.isNotEmpty && _searchResults.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Пользователи не найдены',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          setState(() {
                            _selectedUser = user;
                            _searchResults = [];
                            _searchController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
            const SizedBox(height: 24),
          ],

          const Text(
            'Выберите шаблон',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('✨ Доступно обновление'),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                onPressed: () => _applyTemplate(
                  title: 'Доступно обновление 🚀',
                  message: 'Выпущена новая версия приложения! Пожалуйста, обновите приложение, чтобы получить доступ к новым функциям и улучшениям.',
                  type: NotificationType.alert,
                ),
              ),
              ActionChip(
                label: const Text('📰 Важные новости'),
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                onPressed: () => _applyTemplate(
                  title: 'Важные новости 📰',
                  message: 'Мы добавили много новых университетов!',
                  type: NotificationType.news,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Содержание уведомления',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<NotificationType>(
            key: ValueKey(_selectedType),
            initialValue: _selectedType,
            decoration: InputDecoration(
              labelText: 'Тип уведомления',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: NotificationType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedType = val);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Заголовок',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Текст уведомления',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: 'Ссылка (actionUrl, например для обновления)',
              hintText: 'https://...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSending ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSending
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'ОТПРАВИТЬ УВЕДОМЛЕНИЕ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
