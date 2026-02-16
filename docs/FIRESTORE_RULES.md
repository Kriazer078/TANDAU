# Firebase Security Rules для системы лайков и отзывов

## 📋 Копируйте и вставляйте в Firebase Console → Firestore → Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ========================================
    // УНИВЕРСИТЕТЫ
    // ========================================
    match /universities/{universityId} {
      // Чтение - все
      allow read: if true;
      
      // Запись - только аутентифицированные
      // (для миграции данных админами)
      allow write: if request.auth != null;
    }
    
    // ========================================
    // ЛАЙКИ
    // ========================================
    match /likes/{likeId} {
      // Чтение - все аутентифицированные
      allow read: if request.auth != null;
      
      // Создание - только свой лайк
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.keys().hasAll(['userId', 'universityId', 'createdAt']);
      
      // Удаление - только свой лайк
      allow delete: if request.auth != null 
                    && resource.data.userId == request.auth.uid;
      
      // Обновление - запрещено (лайки не обновляются)
      allow update: if false;
    }
    
    // ========================================
    // ОТЗЫВЫ
    // ========================================
    match /reviews/{reviewId} {
      // Чтение - все
      allow read: if true;
      
      // Создание - только аутентифицированные
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.rating is int
                    && request.resource.data.rating >= 1
                    && request.resource.data.rating <= 5
                    && request.resource.data.comment is string
                    && request.resource.data.comment.size() > 0
                    && request.resource.data.comment.size() <= 1000;
      
      // Обновление - только свой отзыв
      allow update: if request.auth != null 
                    && resource.data.userId == request.auth.uid
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.rating is int
                    && request.resource.data.rating >= 1
                    && request.resource.data.rating <= 5
                    && request.resource.data.comment is string
                    && request.resource.data.comment.size() > 0
                    && request.resource.data.comment.size() <= 1000;
      
      // Удаление - только свой отзыв
      allow delete: if request.auth != null 
                    && resource.data.userId == request.auth.uid;
    }
    
    // ========================================
    // ПОЛЬЗОВАТЕЛИ
    // ========================================
    match /users/{userId} {
      // Чтение и запись - только свои данные
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
    }
    
    // ========================================
    // СРАВНЕНИЯ
    // ========================================
    match /comparisons/{comparisonId} {
      // Чтение и запись - только свои данные
      allow read, write: if request.auth != null 
                         && request.auth.uid == comparisonId;
    }
  }
}
```

## 🔐 Объяснение правил:

### Лайки (likes):
- ✅ Каждый может читать лайки (для отображения счетчиков)
- ✅ Можно создать лайк только от своего имени
- ✅ Можно удалить только свой лайк
- ❌ Нельзя обновлять лайки (только создание/удаление)

### Отзывы (reviews):
- ✅ Все могут читать отзывы
- ✅ Валидация рейтинга (1-5 звезд)
- ✅ Валидация комментария (не пустой, не больше 1000 символов)
- ✅ Можно редактировать/удалять только свой отзыв
- ❌ Нельзя изменить userId при обновлении

### Университеты (universities):
- ✅ Все могут читать
- ✅ Только аутентифицированные могут писать (для админов)

### Безопасность:
- 🔒 Защита от подделки userId
- 🔒 Валидация данных на уровне базы
- 🔒 Предотвращение спама (лимит символов)
- 🔒 Атомарные операции через batch writes

## 📊 Индексы (создайте в Firebase Console):

### For likes collection:
- Composite index: `userId` (Ascending) + `universityId` (Ascending)

### For reviews collection:
- Composite index: `universityId` (Ascending) + `createdAt` (Descending)
- Composite index: `userId` (Ascending) + `universityId` (Ascending)

Firebase автоматически предложит создать индексы при первом запросе!
