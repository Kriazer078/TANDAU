# Функция сравнения университетов / University Comparison Feature

## Описание / Description

### RU
Новая функция сравнения позволяет пользователям добавлять до 4 университетов в список сравнения и просматривать их характеристики рядом друг с другом в удобной таблице.

### EN
The new comparison feature allows users to add up to 4 universities to a comparison list and view their characteristics side-by-side in a convenient table.

### KK
Жаңа салыстыру функциясы пайдаланушыларға 4 университетті салыстыру тізіміне қосуға және олардың сипаттамаларын ыңғайлы кестеде қарап-салыстыруға мүмкіндік береді.

## Сравниваемые параметры / Comparison Parameters / Салыстырылатын параметрлер

1. **Название / Name / Атауы** - Наименование университета
2. **Город / City / Қала** - Местоположение
3. **Стоимость обучения / Tuition Cost / Оқу құны** - Диапазон годовой оплаты
4. **Гранты/Бюджет / Grants/Budget / Гранттар/Бюджет** - Наличие грантов и бюджетных мест
5. **Рейтинг / Rating / Рейтинг** - Оценка студентов (1-5)
6. **Специальности / Specialties / Мамандықтар** - Список доступных специальностей

## Технические детали / Technical Details

### Созданные файлы / Created Files

1. **models/comparison.dart** - Модель данных для хранения списка сравнения
2. **services/comparison_service.dart** - Сервис для работы с Firebase
3. **screens/comparison_screen.dart** - Экран отображения сравнения
4. **Updated: widgets/university_card.dart** - Добавлена кнопка сравнения
5. **Updated: theme/app_colors.dart** - Добавлены цвета для темной темы

### Firebase Integration

Данные сравнения хранятся в Firestore в коллекции `comparisons`:

```
comparisons/
  {userId}/
    - userId: string
    - universityIds: array<string>
    - createdAt: timestamp
    - updatedAt: timestamp
```

### Использование / Usage

#### 1. Добавление университета в сравнение

```dart
final comparisonService = ComparisonService();
await comparison Service.addToComparison(universityId);
```

#### 2. Удаление из сравнения

```dart
await comparisonService.removeFromComparison(universityId);
```

#### 3. Получение списка сравнения

```dart
final universities = await comparisonService.getComparisonUniversities();
```

#### 4. Проверка наличия в сравнении

```dart
final isInComparison = await comparisonService.isInComparison(universityId);
```

### Ограничения / Limitations

- Максимум 4 университета в списке сравнения
- Требуется авторизация пользователя
- Данные синхронизируются с Firebase в реальном времени

### Локализация / Localization

Добавлены строки локализации для 3 языков:
- Русский (RU)
- Английский (EN)
- Казахский (KK)

Ключевые строки:
- `comparisonTitle` - Заголовок экрана
- `comparisonEmpty` - Сообщение о пустом списке
- `comparisonAdded` - Уведомление о добавлении
- `comparisonRemoved` - Уведомление об удалении
- `comparisonFull` - Достигнут лимит
- `comparisonParam*` - Названия параметров

## Интеграция в навигацию / Navigation Integration

Для навигации к экрану сравнения:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ComparisonScreen(),
  ),
);
```

## UI/UX Features

1. **Horizontal Scrolling** - Таблица с горизонтальной прокруткой для удобного просмотра
2. **Color Coding** - Цветовая индикация для грантов и рейтинга
3. **Empty State** - Красивый экран для пустого списка с призывом к действию
4. **Dark Mode Support** - Полная поддержка темной темы
5. **Real-time Updates** - Данные обновляются в реальном времени через Firebase

## Следующие шаги / Next Steps

1. Добавить кнопку "Сравнить" в главную навигацию приложения
2. Добавить бейдж с количеством университетов в сравнении
3. Интегрировать кнопку сравнения в `university_list_screen.dart`
4. Добавить возможность экспорта сравнения (PDF/изображение)
5. Добавить push-уведомления при изменениях в сравниваемых университетах

---

**Дата создания:** 13 февраля 2026  
**Версия:** 1.0.0  
**Автор:** TANDAU Development Team
