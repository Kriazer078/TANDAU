# 🔥 Инструкция по миграции данных в Firestore

## 📋 Что нужно знать

Миграция переносит все университеты из локальных данных (`lib/data/universities.dart`) в Firestore Database.

## 🚀 Способ 1: Автоматическая миграция (Рекомендуется)

### Уже готово! ✅

Код миграции уже добавлен в `lib/main.dart`. Просто запустите приложение:

```bash
flutter run
```

### Что происходит:

1. При первом запуске проверяется Firestore
2. Если университетов нет - они загружаются автоматически
3. Если университеты уже есть - миграция пропускается
4. Результаты выводятся в консоль

### Консоль покажет:

```
🔄 Проверка миграции данных...
Universities already exist in Firestore (10 found)
Skipping migration. If you want to re-migrate, delete the collection first.
✅ Successfully migrated universities to Firestore
Total universities in Firestore: 10
Unique cities: 5
Unique majors: 25
✅ Firestore data verification complete
```

### После успешной миграции:

Закомментируйте код миграции в `lib/main.dart` (строки 18-28):

```dart
// 🔥 МИГРАЦИЯ ДАННЫХ В FIRESTORE (запустится один раз)
// После успешной миграции можете закомментировать эти строки
/*
try {
  final migrationHelper = DataMigrationHelper();
  debugPrint('🔄 Проверка миграции данных...');
  await migrationHelper.migrateUniversitiesToFirestore();
  await migrationHelper.verifyFirestoreData();
} catch (e) {
  debugPrint('⚠️ Ошибка миграции: $e');
}
*/
```

## 🎛️ Способ 2: Ручная миграция через UI

Добавьте кнопку в ProfileScreen для доступа к админ-панели:

```dart
// В lib/screens/profile_screen.dart
// Добавьте после других настроек:

_buildSettingCard(
  context,
  icon: Icons.admin_panel_settings,
  title: 'Миграция данных',
  subtitle: 'Загрузить университеты в Firestore',
  trailing: Icon(
    Icons.arrow_forward_ios,
    size: 16,
    color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminMigrationScreen(),
      ),
    );
  },
),
```

Не забудьте импорт:
```dart
import 'admin_migration_screen.dart';
```

### Возможности админ-панели:

- ✅ **Запустить миграцию** - загрузить университеты
- 🔍 **Проверить данные** - вывести статистику в консоль
- 🗑️ **Удалить все данные** - очистить Firestore (с подтверждением)

## 📊 Проверка миграции

### 1. В Firebase Console:

1. Откройте [Firebase Console](https://console.firebase.google.com/)
2. Выберите проект `tandau-app`
3. Firestore Database → Data
4. Должна появиться коллекция `universities`

### 2. В консоли приложения:

```
Total universities in Firestore: 10
Unique cities: 5
Unique majors: 25
```

### 3. В приложении:

- Откройте список университетов
- Должны загрузиться все университеты из Firestore

## ⚠️ Устранение проблем

### Ошибка: "Permission denied"

**Решение**: Настройте правила Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /universities/{document=**} {
      allow read: if true;
      allow write: if true; // Временно для миграции
    }
  }
}
```

### Ошибка: "Collection already exists"

Это нормально! Миграция пропустится автоматически.

Если хотите переми грировать заново:
1. Откройте Firebase Console
2. Удалите коллекцию `universities`
3. Запустите миграцию снова

### Данные не отображаются в приложении

1. Проверьте консоль на ошибки
2. Убедитесь, что интернет подключен
3. Проверьте правила безопасности Firestore
4. Перезапустите приложение

## 🔄 Повторная миграция

Если хотите обновить данные в Firestore:

### Вариант 1: Через админ-панель

1. Откройте Admin Migration Screen
2. Нажмите "Удалить все данные"
3. Нажмите "Запустить миграцию"

### Вариант 2: Через Firebase Console

1. Откройте Firestore Database
2. Удалите коллекцию `universities`
3. Раскомментируйте код в `main.dart`
4. Перезапустите приложение

## 📝 Что мигрируется

Для каждого университета:
- ✅ ID, название, город
- ✅ Логотип, изображения
- ✅ Специальности (majors)
- ✅ Проходной балл, стоимость обучения
- ✅ Наличие общежития и грантов
- ✅ Описание, требования
- ✅ Дедлайн подачи заявок
- ✅ Адрес, веб-сайт
- ✅ Рейтинг, количество студентов

## ✨ После миграции

Ваше приложение теперь:
- 📊 Использует Cloud Firestore для университетов
- ⚡ Поддерживает real-time обновления
- 🔄 Позволяет синхронизацию данных
- 📱 Работает на всех устройствах пользователя
- 🔐 Использует Firebase Authentication для пользователей

## 🎯 Следующие шаги

1. ✅ Миграция университетов
2. 🔒 Настройте правила безопасности Firestore
3. 📊 Создайте индексы для быстрого поиска
4. 🧪 Протестируйте регистрацию и вход
5. ⭐ Протестируйте добавление в избранное

---

**Готово!** Если возникли вопросы, проверьте [FIREBASE_GUIDE.md](./FIREBASE_GUIDE.md)
