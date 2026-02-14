# Firebase Integration Guide

## 📋 Обзор

Приложение TANDAU теперь полностью интегрировано с Firebase для хранения данных пользователей и университетов.

## 🔥 Настроенные Firebase сервисы

### 1. Firebase Authentication
- Регистрация пользователей с email и паролем
- Вход в систему
- Управление сессиями
- Выход из системы

### 2. Cloud Firestore
- Хранение данных пользователей
- Хранение информации об университетах
- Избранные университеты пользователя
- Real-time обновления данных

## 📁 Структура данных в Firestore

### Коллекция `users`
```
users/{userId}
  ├── uid: string
  ├── name: string
  ├── email: string
  ├── phone: string (optional)
  ├── createdAt: timestamp
  ├── updatedAt: timestamp (optional)
  └── favoriteUniversities: array<string>
```

### Коллекция `universities`
```
universities/{universityId}
  ├── id: string
  ├── name: string
  ├── city: string
  ├── logoUrl: string
  ├── imageUrls: array<string>
  ├── majors: array<string>
  ├── passingScore: number
  ├── tuitionRange: string
  ├── hasDormitory: boolean
  ├── hasGrants: boolean
  ├── description: string
  ├── requirements: array<string>
  ├── applicationDeadline: string
  ├── address: string
  ├── website: string
  ├── rating: number
  └── studentCount: number
```

## 🚀 Миграция данных

### Автоматическая миграция университетов

Для загрузки локальных данных университетов в Firestore, используйте `DataMigrationHelper`:

```dart
import 'package:tandau/utils/data_migration_helper.dart';

// В main.dart или в отдельном скрипте
final migrationHelper = DataMigrationHelper();

// Миграция университетов
await migrationHelper.migrateUniversitiesToFirestore();

// Проверка данных
await migrationHelper.verifyFirestoreData();
```

### Ручная миграция (через Firebase Console)

1. Откройте Firebase Console
2. Перейдите в Firestore Database
3. Создайте коллекцию `universities`
4. Импортируйте данные из JSON файла

## 📝 Использование сервисов

### AuthService

```dart
import 'package:tandau/services/auth_service.dart';

final authService = AuthService();

// Регистрация
await authService.register(
  'Имя Пользователя',
  'email@example.com',
  'password123',
  phone: '+7 777 777 77 77',
);

// Вход
await authService.login('email@example.com', 'password123');

// Добавить в избранное
await authService.addToFavorites('university_id');

// Удалить из избранного
await authService.removeFromFavorites('university_id');

// Проверить избранное
bool isFav = authService.isFavorite('university_id');

// Выход
await authService.logout();
```

### UniversityService

```dart
import 'package:tandau/services/university_service.dart';

final universityService = UniversityService();

// Получить все университеты
List<University> universities = await universityService.getAllUniversities();

// Получить stream университетов (real-time)
Stream<List<University>> stream = universityService.getUniversitiesStream();

// Фильтрация
List<University> filtered = await universityService.filterUniversities(
  city: ['Алматы', 'Астана'],
  major: ['IT', 'Бизнес'],
  searchQuery: 'КазНУ',
);

// Получить избранные
List<University> favorites = await universityService.getFavoriteUniversities();

// Получить университет по ID
University? uni = await universityService.getUniversityById('uni_id');
```

### FirestoreService (низкоуровневый)

```dart
import 'package:tandau/services/firestore_service.dart';

final firestoreService = FirestoreService();

// CRUD операции
await firestoreService.addUniversity(university);
await firestoreService.updateUniversity(university);
await firestoreService.deleteUniversity('uni_id');

// Batch операции
await firestoreService.batchUploadUniversities(universities);

// Получить уникальные города
List<String> cities = await firestoreService.getUniqueCities();

// Получить уникальные специальности
List<String> majors = await firestoreService.getUniqueMajors();
```

## ⚙️ Настройка

### Переключение между Firestore и локальными данными

```dart
final universityService = UniversityService();

// Использовать Firestore (по умолчанию)
universityService.setUseFirestore(true);

// Использовать локальные данные
universityService.setUseFirestore(false);
```

## 🔒 Правила безопасности Firestore

Рекомендуемые правила для Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Пользователь может читать и изменять только свои данные
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Universities collection
    match /universities/{universityId} {
      // Все могут читать
      allow read: if true;
      // Только аутентифицированные пользователи могут писать (для будущего функционала)
      allow write: if request.auth != null;
    }
  }
}
```

## 🐛 Отладка

### Проверка подключения к Firebase

```dart
import 'package:firebase_core/firebase_core.dart';

// В main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  runApp(const TandauApp());
}
```

### Логирование операций

Все сервисы используют `debugPrint` для логирования. Проверьте консоль для:
- Ошибок аутентификации
- Ошибок Firestore
- Статуса миграции данных

## 📱 Следующие шаги

1. **Миграция данных**: Запустите миграцию университетов в Firestore
2. **Тестирование**: Проверьте регистрацию, вход и работу с избранным
3. **Правила безопасности**: Настройте правила в Firebase Console
4. **Индексы**: Создайте необходимые индексы для фильтрации (Firebase покажет ссылки в консоли)
5. **Оптимизация**: Добавьте кэширование для часто используемых данных

## 🔗 Полезные ссылки

- [Firebase Console](https://console.firebase.google.com/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
