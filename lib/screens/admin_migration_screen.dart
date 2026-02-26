import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../utils/data_migration_helper.dart';

/// Экран для администратора для управления миграцией данных
class AdminMigrationScreen extends StatefulWidget {
  const AdminMigrationScreen({super.key});

  @override
  State<AdminMigrationScreen> createState() => _AdminMigrationScreenState();
}

class _AdminMigrationScreenState extends State<AdminMigrationScreen> {
  final DataMigrationHelper _migrationHelper = DataMigrationHelper();
  bool _isMigrating = false;
  String _statusMessage = 'Готово к миграции';
  bool _hasError = false;

  Future<void> _runMigration() async {
    setState(() {
      _isMigrating = true;
      _statusMessage = 'Миграция данных...';
      _hasError = false;
    });

    try {
      final success = await _migrationHelper.migrateUniversitiesToFirestore();

      if (success) {
        await _migrationHelper.verifyFirestoreData();
        setState(() {
          _statusMessage = '✅ Миграция успешно завершена!';
          _hasError = false;
        });
      } else {
        setState(() {
          _statusMessage = '⚠️ Миграция завершилась с ошибками';
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка: $e';
        _hasError = true;
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _forceUpdateData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔄 Обновление данных'),
        content: const Text(
          'Это перезапишет ВСЕ данные университетов в Firestore '
          'актуальными данными из приложения.\n\n'
          'Контакты, адреса и другие данные будут обновлены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Обновить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isMigrating = true;
      _statusMessage = 'Обновление данных в Firestore...';
      _hasError = false;
    });

    try {
      final success = await _migrationHelper.migrateUniversitiesToFirestore(
        forceOverwrite: true,
      );

      if (success) {
        setState(() {
          _statusMessage = '✅ Данные успешно обновлены в Firestore!';
          _hasError = false;
        });
      } else {
        setState(() {
          _statusMessage = '⚠️ Обновление завершилось с ошибками';
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка обновления: $e';
        _hasError = true;
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _verifyData() async {
    setState(() {
      _isMigrating = true;
      _statusMessage = 'Проверка данных...';
      _hasError = false;
    });

    try {
      await _migrationHelper.verifyFirestoreData();
      setState(() {
        _statusMessage = '✅ Проверка завершена (смотрите консоль)';
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка проверки: $e';
        _hasError = true;
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _clearData() async {
    // Показать диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Внимание!'),
        content: const Text(
          'Вы уверены, что хотите удалить ВСЕ университеты из Firestore?\n\n'
          'Это действие нельзя отменить!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isMigrating = true;
      _statusMessage = 'Удаление данных...';
      _hasError = false;
    });

    try {
      final success = await _migrationHelper.clearUniversitiesFromFirestore();

      if (success) {
        setState(() {
          _statusMessage = '✅ Все данные удалены';
          _hasError = false;
        });
      } else {
        setState(() {
          _statusMessage = '⚠️ Удаление завершилось с ошибками';
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка удаления: $e';
        _hasError = true;
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _generateDummyStats() async {
    setState(() {
      _isMigrating = true;
      _statusMessage = 'Генерация тестовой статистики...';
      _hasError = false;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final random = Random();

      // Генерируем данные за последние 30 дней
      for (int i = 0; i < 30; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        // YYYY-MM-DD
        final dateStr = date.toIso8601String().split('T')[0];

        // Имитируем разные значения
        final newUsers = random.nextInt(15); // 0-14 новых юзеров
        final newReviews = random.nextInt(8); // 0-7 новых отзывов

        await firestore.collection('statistics').doc(dateStr).set({
          'new_users': newUsers,
          'new_reviews': newReviews,
          'date': Timestamp.fromDate(date),
        }, SetOptions(merge: true));
      }

      setState(() {
        _statusMessage = '✅ Тестовая статистика сгенерирована!';
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка генерации: $e';
        _hasError = true;
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Миграция данных'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _hasError ? Colors.red.shade50 : Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      _isMigrating
                          ? Icons.sync
                          : _hasError
                          ? Icons.error
                          : Icons.check_circle,
                      size: 48,
                      color: _hasError ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Info
            const Text(
              'Что делает миграция?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Загружает все университеты из локальных данных\n'
              '• Сохраняет их в Firestore Database\n'
              '• Проверяет корректность данных\n'
              '• Пропускает, если данные уже есть',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Migration Button
            ElevatedButton.icon(
              onPressed: _isMigrating ? null : _runMigration,
              icon: _isMigrating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload),
              label: Text(
                _isMigrating ? 'Миграция...' : 'Запустить миграцию',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Force Update Button (overwrites Firestore with local data)
            ElevatedButton.icon(
              onPressed: _isMigrating ? null : _forceUpdateData,
              icon: const Icon(Icons.sync, color: Colors.white),
              label: const Text(
                'Обновить данные (Перезапись)',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Verify Button
            OutlinedButton.icon(
              onPressed: _isMigrating ? null : _verifyData,
              icon: const Icon(Icons.verified),
              label: const Text('Проверить данные'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Clear Button
            OutlinedButton.icon(
              onPressed: _isMigrating ? null : _clearData,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Удалить все данные'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Dummy Data Button
            OutlinedButton.icon(
              onPressed: _isMigrating ? null : _generateDummyStats,
              icon: const Icon(Icons.show_chart),
              label: const Text('Generate Dummy Stats (Test)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const Spacer(),

            // Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Colors.amber, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Совет: После успешной миграции закомментируйте код миграции в main.dart',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
