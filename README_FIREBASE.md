# 🔥 Firebase Integration - TANDAU App

## ✅ Что сделано

### 1. **Модели данных**
- ✅ `UserModel` - модель пользователя с методами для Firestore
- ✅ `University` - обновлена с методами `toMap()` и `fromMap()`

### 2. **Сервисы**
- ✅ **AuthService** - полная интеграция с Firebase Authentication
  - Регистрация пользователей
  - Вход/выход
  - Управление избранными университетами
  - Обновление профиля
  
- ✅ **FirestoreService** - работа с Cloud Firestore
  - CRUD операции для университетов
  - Фильтрация и поиск
  - Batch операции
  
- ✅ **UniversityService** - обновлён для работы с Firestore
  - Поддержка async операций
  - Fallback на локальные данные

### 3. **Экраны**
- ✅ ProfileScreen - обновлён для работы с UserModel
- ✅ FilterScreen - исправлены async операции
- ✅ SearchScreen - исправлены async операции
- ✅ UniversityListScreen - исправлены async операции

### 4. **Утилиты**
- ✅ DataMigrationHelper - миграция данных в Firestore

## 📊 Структура Firestore

### Коллекция `users`
```
users/{userId}
  - uid: string
  - name: string
  - email: string
  - phone: string (опционально)
  - createdAt: timestamp
  - updatedAt: timestamp
  - favoriteUniversities: array<string>
```

### Коллекция `universities`
```
universities/{universityId}
  - id, name, city, logoUrl
  - imageUrls, majors, requirements
  - passingScore, tuitionRange
  - hasDormitory, hasGrants
  - description, applicationDeadline
  - address, website
  - rating, studentCount
```

## 🚀 Как использовать

### Шаг 1: Миграция данных
Добавьте в `main.dart` (временно, для первого запуска):

```dart
import 'utils/data_migration_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Миграция данных (запустить один раз)
  final migrationHelper = DataMigrationHelper();
  await migrationHelper.migrateUniversitiesToFirestore();
  await migrationHelper.verifyFirestoreData();
  
  await ThemeManager().init();
  await LocaleManager().init();
  await AuthService().init();
  
  runApp(const TandauApp());
}
```

### Шаг 2: Настройка правил безопасности
В Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /universities/{universityId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Шаг 3: Тестирование

1. **Регистрация**: Создайте нового пользователя
2. **Вход**: Войдите с созданными учётными данными
3. **Избранное**: Добавьте университеты в избранное
4. **Профиль**: Проверьте отображение данных пользователя

## 📝 Примеры использования

### Регистрация
```dart
final success = await AuthService().register(
  'Иван Иванов',
  'ivan@example.com',
  'password123',
  phone: '+7 777 777 77 77',
);
```

### Вход
```dart
final success = await AuthService().login(
  'ivan@example.com',
  'password123',
);
```

### Работа с избранным
```dart
// Добавить в избранное
await AuthService().addToFavorites('university_id');

// Удалить из избранного
await AuthService().removeFromFavorites('university_id');

// Проверить
bool isFav = AuthService().isFavorite('university_id');
```

### Получение университетов
```dart
// Все университеты
List<University> all = await UniversityService().getAllUniversities();

// С фильтрами
List<University> filtered = await UniversityService().filterUniversities(
  city: ['Алматы'],
  major: ['IT'],
  searchQuery: 'КазНУ',
);

// Избранные
List<University> favorites = await UniversityService().getFavoriteUniversities();
```

## 🔧 Troubleshooting

### Проблема: "Firebase not initialized"
**Решение**: Убедитесь, что `Firebase.initializeApp()` вызывается до использования сервисов

### Проблема: "Permission denied"
**Решение**: Проверьте правила безопасности в Firestore Console

### Проблема: "No universities found"
**Решение**: Запустите миграцию данных через `DataMigrationHelper`

## 📚 Документация

Полная документация: [FIREBASE_GUIDE.md](./FIREBASE_GUIDE.md)

## ⚠️ Важно

- После первой миграции удалите код миграции из `main.dart`
- Храните `google-services.json` и `firebase_options.dart` в безопасности
- Не коммитьте конфиденциальные данные в Git
