# 📚 Документация: Система лайков и отзывов

## 🎯 Обзор системы

Профессиональная реализация системы лайков и отзывов с:
- ✅ Оптимизацией производительности (отдельная коллекция likes)
- ✅ Атомарными операциями (Firestore batch)
- ✅ Автоматическим расчетом среднего рейтинга
- ✅ Security Rules для защиты данных
- ✅ Real-time синхронизацией UI

---

## 📁 Структура файлов

```
lib/
├── models/
│   ├── like.dart                    # Модель лайка
│   ├── review.dart                  # Модель отзыва
│   └── university.dart              # Обновлена (+ likesCount, reviewsCount, averageRating)
│
├── services/
│   ├── like_service.dart            # Сервис работы с лайками
│   └── review_service.dart          # Сервис работы с отзывами
│
└── widgets/
    └── like_review_widgets.dart     # UI компоненты
```

---

## 🚀 Быстрый старт

### 1️⃣ Примен использования в UI

#### Кнопка лайка на карточке университета:

```dart
import 'package:flutter/material.dart';
import '../widgets/like_review_widgets.dart';

class UniversityCard extends StatelessWidget {
  final University university;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // ... другие виджеты
          
          Row(
            children: [
              // ⭐ Кнопка лайка с анимацией
              LikeButton(
                universityId: university.id,
                initialLikesCount: university.likesCount,
              ),
              
              const Spacer(),
              
              // ⭐ Отображение рейтинга
              RatingDisplay(
                rating: university.averageRating,
                reviewsCount: university.reviewsCount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### Кнопка "Оставить отзыв":

```dart
ElevatedButton(
  onPressed: () async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddReviewDialog(
        universityId: university.id,
      ),
    );
    
    if (result == true) {
      // Отзыв добавлен, обновите UI
      setState(() {});
    }
  },
  child: const Text('Оставить отзыв'),
)
```

#### Список отзывов (real-time):

```dart
import '../services/review_service.dart';
import '../models/review.dart';

class ReviewsList extends StatelessWidget {
  final String universityId;
  final ReviewService _reviewService = ReviewService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: _reviewService.getUniversityReviewsStream(universityId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final reviews = snapshot.data!;
        
        return ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return ListTile(
              title: Text(review.userName),
              subtitle: Text(review.comment),
              leading: RatingDisplay(
                rating: review.rating.toDouble(),
                showCount: false,
              ),
              trailing: Text(
                _formatDate(review.createdAt),
                style: TextStyle(color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
  
  String _formatDate(DateTime date) {
    // Форматирование даты
    return '${date.day}.${date.month}.${date.year}';
  }
}
```

---

## 2️⃣ Прямое использование сервисов

### LikeService

```dart
final likeService = LikeService();

// Toggle лайка
await likeService.toggleLike('universityId123');

// Проверить статус лайка
final isLiked = await likeService.isLiked('universityId123');

// Получить количество лайков
final count = await likeService.getLikesCount('universityId123');

// Stream для real-time обновлений
likeService.getLikeStream('universityId123').listen((isLiked) {
  print('Liked: $isLiked');
});

// Получить все лайкнутые университеты пользователя
final likedUniversities = await likeService.getUserLikedUniversities();
```

### ReviewService

```dart
final reviewService = ReviewService();

// Добавить отзыв
await reviewService.addReview(
  universityId: 'universityId123',
  rating: 5,
  comment: 'Отличный вуз!',
);

// Обновить отзыв
await reviewService.updateReview(
  reviewId: 'reviewId456',
  rating: 4,
  comment: 'Обновленный отзыв',
);

// Удалить отзыв
await reviewService.deleteReview('reviewId456');

// Получить отзыв пользователя
final myReview = await reviewService.getUserReview('universityId123');

// Получить все отзывы университета
final reviews = await reviewService.getUniversityReviews('universityId123');

// Stream отзывов (real-time)
reviewService.getUniversityReviewsStream('universityId123').listen((reviews) {
  print('Reviews count: ${reviews.length}');
});
```

---

## 3️⃣ Настройка Firebase

### Firestore Security Rules

Откройте `Firebase Console → Firestore → Rules` и скопируйте правила из файла `FIRESTORE_RULES.md`.

**Ключевые правила:**
- ✅ Лайки: только создание/удаление своих лайков
- ✅ Отзывы: валидация рейтинга (1-5) и длины комментария (1-1000 символов)
- ✅ Universities: только аутентифицированные могут писать (для миграции)

### Индексы Firestore

Firebase автоматически предложит создать необходимые индексы при первом запросе.

Или создайте вручную:

**likes коллекция:**
```
userId (Ascending) + universityId (Ascending)
```

**reviews коллекция:**
```
universityId (Ascending) + createdAt (Descending)
userId (Ascending) + universityId (Ascending)
```

---

## 4️⃣ Инициализация счетчиков

### Первый запуск (для существующих университетов)

Если у вас уже есть университеты в базе, нужно проинициализировать счетчики:

```dart
import '../services/like_service.dart';
import '../services/review_service.dart';

// В админ-панели или миграции
final likeService = LikeService();
final reviewService = ReviewService();

// Инициализация счетчиков лайков
await likeService.initializeLikesCounters();

// Инициализация рейтингов
await reviewService.initializeRatings();
```

**Это нужно запустить ОДИН РАЗ** после развертывания системы!

---

## 5️⃣ Производительность и оптимизация

### Почему отдельная коллекция для лайков?

✅ **Масштабируемость:**
- 1 университет может иметь тысячи лайков
- Хранение всех лайков в массиве → лимиты Firestore (1MB на документ)

✅ **Быстрые запросы:**
- Композитный индекс `userId + universityId` → O(1) поиск
- Проверка "лайкнул ли пользователь" = 1 чтение

✅ **Атомарные операции:**
- Batch write гарантирует консистентность
- Либо ВСЕ операции прошли, либо НИЧЕГО

### Счетчики vs Подсчет каждый раз

❌ **Плохо** (подсчет при каждом запросе):
```dart
// Это 100+ чтений для 100 лайков!
final likesSnapshot = await firestore
  .collection('likes')
  .where('universityId', isEqualTo: uniId)
  .get();
final count = likesSnapshot.docs.length;
```

✅ **Хорошо** (счетчик):
```dart
// Это 1 чтение!
final doc = await firestore.collection('universities').doc(uniId).get();
final count = doc.data()['likesCount'];
```

---

## 6️⃣ Обработка ошибок

### Пример с обработкой ошибок:

```dart
try {
  final success = await likeService.toggleLike(universityId);
  
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Лайк добавлен!')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка. Войдите в систему')),
    );
  }
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Произошла ошибка: $e')),
  );
}
```

---

## 7️⃣ Тестирование

### Проверка работы системы:

```dart
void testLikesAndReviews() async {
  final likeService = LikeService();
  final reviewService = ReviewService();
  
  // 1. Проверка лайков
  print('Testing likes...');
  await likeService.toggleLike('test_university_id');
  final isLiked = await likeService.isLiked('test_university_id');
  assert(isLiked == true, 'Like should be active');
  
  // 2. Проверка отзывов
  print('Testing reviews...');
  await reviewService.addReview(
    universityId: 'test_university_id',
    rating: 5,
    comment: 'Test review',
  );
  
  final reviews = await reviewService.getUniversityReviews('test_university_id');
  assert(reviews.isNotEmpty, 'Should have at least one review');
  
  print('✅ All tests passed!');
}
```

---

## 🎓 Лучшие практики

1. **Всегда проверяйте авторизацию** перед операциями
2. **Используйте оптимистичные обновления UI** (сначала UI, потом Firebase)
3. **Обрабатывайте ошибки грейсфулли**
4. **Кэшируйте данные где возможно**
5. **Используйте Streams для real-time обновлений**
6. **Валидируйте данные на клиенте И в Security Rules**

---

## 📞 Поддержка

При возникновении проблем:
1. Проверьте Security Rules в Firebase Console
2. Проверьте индексы Firestore
3. Посмотрите Debug Console на наличие ошибок
4. Убедитесь что пользователь аутентифицирован

---

**🎉 Готово! Система лайков и отзывов полностью настроена и готова к использованию!**
