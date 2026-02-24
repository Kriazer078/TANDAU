<div align="center">
  <img src="assets/images/icon.jpg" width="150" height="150" alt="TANDAU Logo">
  
  <h1>🌟 TANDAU</h1>
  <p><strong>Talent Analysis & Navigation for Dream University</strong></p>
  <p><em>Инновационный навигатор для абитуриентов Казахстана, помогающий уверенно выбрать университет мечты и оценить шансы на образовательный грант.</em></p>

  <p>
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
    <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
    <a href="https://firebase.google.com/"><img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=white" alt="Firebase"></a>
    <a href="https://riverpod.dev/"><img src="https://img.shields.io/badge/State_Management-Riverpod-1A1A1A?style=for-the-badge&logo=dart&logoColor=white" alt="Riverpod"></a>
    <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=for-the-badge&logo=android&logoColor=white" alt="Platform">
    <img src="https://img.shields.io/badge/Version-1.0.2-blue?style=for-the-badge" alt="Version">
  </p>

  <h3>🚀 Скоро на <a href="https://play.google.com/">Google Play</a> | <a href="https://github.com/Kriazer078/TANDAU/releases/latest/download/app-release.apk">Скачать APK (Android)</a></h3>
</div>

---

## ✨ Ключевые возможности

### 📊 **Умный расчёт шансов на грант**
Алгоритм оценивает ваш балл ЕНТ относительно реального проходного балла каждого университета. Используется нелинейная модель расчёта, учитывающая: ГПА, IELTS, олимпиадные достижения, город проживания и специальность. Результат — точный персональный процент шанса по каждому вузу.

### 🤖 **AI-Консультант (Gemini AI)**
Персональный ИИ-советник, который генерирует стратегию поступления с учётом ваших данных, трендов IT-рынка и государственных программ (Серпін, квоты). Предлагает **персональную стратегию по 4 университетам** — гарантированный, оптимальный, амбициозный и запасной вариант. Каждый пользователь получает **1000 бесплатных AI-запросов в день**.

### 🎓 **Умный поиск и подбор университетов**
Более 30 ведущих университетов Казахстана с детальной информацией: специальности, проходные баллы, стоимость обучения, наличие общежитий, сроки приёма документов, квоты и гранты.

### 🛡️ **Система подписок TANDAU+**
Многоуровневый доступ к аналитике:
- **Basic** — 1000 AI-запросов/день, базовый расчёт шансов *(бесплатно)*
- **PRO** — расширенная аналитика, приоритетные ответы ИИ
- **Premium** — полная аналитика, персональный план, отсутствие ограничений

### 📱 **Премиум пользовательский опыт**
- 🌍 **Мультиязычность**: Казахский, Русский, Английский
- 🌙 **Тёмная/Светлая темы**: Material 3 с премиум-дизайном и анимациями
- ❤️ **Избранное**: Сохраняйте вузы для быстрого сравнения
- 🔔 **Push-уведомления**: Напоминания о дедлайнах и новости

---

## 🛠️ Технологический стек

| Слой | Технология |
| :--- | :--- |
| **Frontend** | Flutter 3.x (Dart 3.x) |
| **State Management** | flutter_riverpod + ValueNotifier |
| **База данных** | Firebase Firestore |
| **Авторизация** | Firebase Auth (Email, Google Sign-In, Анонимная) |
| **Push-уведомления** | Firebase Cloud Messaging (FCM) |
| **Хранилище** | Firebase Storage |
| **Серверная логика** | Dart Shelf + Shelf Router (деплой: [Render.com](https://tandau-backend.onrender.com)) |
| **AI** | Google Gemini API |
| **Подписки** | RevenueCat |
| **UI** | google_fonts, shimmer, fl_chart, lottie, percent_indicator |
| **Package ID (Android)** | `kz.tandau.app` |

---

## 🏗️ Архитектура проекта

```text
tandau/
├── lib/
│   ├── main.dart                      # Точка входа
│   ├── firebase_options.dart          # Firebase конфигурация
│   ├── l10n/                          # Локализация (ru, kk, en)
│   ├── data/
│   │   └── universities.dart          # Данные по университетам
│   ├── models/                        # Dart-модели (User, University, ...)
│   ├── providers/                     # Riverpod провайдеры
│   ├── screens/                       # Экраны приложения
│   │   ├── home_screen.dart           # Главный экран с расчётом ЕНТ
│   │   ├── grant_prediction_results_screen.dart  # Результаты предсказания
│   │   ├── university_detail_screen.dart   # Детали вуза + AI стратегия
│   │   ├── ai_consultant_screen.dart  # Чат с AI-консультантом
│   │   ├── paywall_screen.dart        # Экран подписок TANDAU+
│   │   └── admin/                     # Панель администратора
│   ├── services/                      # Бизнес-логика
│   │   ├── auth_service.dart          # Авторизация
│   │   ├── grant_chance_service.dart  # Алгоритм расчёта шансов
│   │   ├── ai_consultant_service.dart # Интеграция с Gemini AI
│   │   ├── revenuecat_service.dart    # Управление подписками
│   │   └── notification_service.dart  # Push-уведомления
│   ├── theme/                         # Цвета и темы
│   └── widgets/                       # Переиспользуемые компоненты
│
├── backend_dart/                      # Dart Shelf сервер
│   ├── bin/server.dart                # Точка входа сервера
│   ├── lib/controllers/              # Контроллеры API
│   └── lib/services/                 # Gemini, Firebase сервисы
│
└── android/                           # Android-специфичные файлы
    └── app/google-services.json      # Firebase Android конфиг
```

---

## 🚀 Как запустить локально

### 1. Предварительные требования
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (версия 3.x)
- Android Studio или VS Code с плагинами Flutter и Dart
- Физическое устройство или эмулятор (Android API 21+ / iOS 13+)
- Аккаунт Firebase с настроенным проектом

### 2. Клонирование и установка

```bash
git clone https://github.com/Kriazer078/TANDAU.git
cd TANDAU
flutter pub get
```

### 3. Запуск

```bash
# Debug режим
flutter run

# Release APK
flutter build apk --release

# Release AAB (для Google Play)
flutter build appbundle --release
```

### 4. Запуск backend-сервера локально

```bash
cd backend_dart
dart pub get
dart run bin/server.dart
```

---

## 🌐 API эндпоинты (Backend)

Базовый URL: `https://tandau-backend.onrender.com`

| Метод | Эндпоинт | Описание |
| :--- | :--- | :--- |
| `GET` | `/health` | Проверка работоспособности |
| `GET` | `/privacy` | Политика конфиденциальности |
| `POST` | `/api/v1/ai/getAIStrategy` | Генерация AI-стратегии поступления |
| `POST` | `/api/v1/notifications/send` | Отправка push-уведомлений |

---

## 📋 Статус проекта

- [x] Базовая авторизация (Email, Google, Аноним)
- [x] Поиск и фильтрация университетов
- [x] Алгоритм расчёта шансов на грант
- [x] AI-консультант (Gemini API)
- [x] Система подписок RevenueCat
- [x] Мультиязычность (ru, kk, en)
- [x] Push-уведомления (FCM)
- [x] Панель администратора
- [x] Google Play публикация *(в процессе верификации)*
- [ ] iOS App Store публикация *(планируется)*

---

## 🔒 Политика конфиденциальности

Политика конфиденциальности доступна по адресу:
**[https://tandau-backend.onrender.com/privacy](https://tandau-backend.onrender.com/privacy)**

---

## 👨‍💻 Команда

Проект разработан командой стартапа **TANDAU**.

> *Миссия: Сделать высшее образование доступным, а процесс выбора университета — понятным и технологичным для каждого абитуриента Казахстана.*

---

<div align="center">
  <p>Сделано с ❤️ в Казахстане 🇰🇿</p>
  <p>
    <a href="https://tandau-backend.onrender.com/privacy">Политика конфиденциальности</a>
  </p>
</div>
