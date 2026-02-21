<div align="center">
  <img src="assets/images/app_icon.jpg" width="150" height="150" alt="TANDAU Logo">
  <h1>TANDAU</h1>
  <p><strong>Talent Analysis & Navigation for Dream University</strong></p>
  <p><em>Инновационный навигатор для абитуриентов Казахстана, помогающий уверенно выбрать университет мечты и оценить шансы на грант.</em></p>

  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase)](https://firebase.google.com/)
  [![Riverpod](https://img.shields.io/badge/State_Management-Riverpod-1A1A1A?logo=dart)](https://riverpod.dev/)

</div>

---

## ✨ Ключевые возможности

🚀 **Умный подбор вузов**
Находите идеальные программы по городу, специальности, стоимости обучения и проходным баллам. Детальная информация по каждому университету: наличие общежитий, грантов и сроки приема документов.

🤖 **AI-Консультант (Алгоритм 4-х вузов)**
Интегрированный искусственный интеллект (Gemini AI), который генерирует персональную стратегию поступления на грант, оценивает ваши шансы на основе баллов ЕНТ и предлагает 4 запасных варианта.

🛡️ **Система подписок TANDAU+**
Многоуровневый доступ к функциям: Basic, PRO и Premium, открывающие безлимитные ИИ-запросы и приоритетную аналитику.

Пользовательский опыт:
- 🌍 **Мультиязычность**: Поддержка казахского, русского и английского языков.
- 🌙 **Адаптивный дизайн**: Современный премиум интерфейс (Material 3) с поддержкой светлой и темной тем.
- ❤️ **Избранное**: Сохраняйте интересующие вузы для быстрого доступа.

---

## 🛠️ Технологический стек

### Frontend
- **Framework**: [Flutter](https://flutter.dev/)
- **Язык**: [Dart](https://dart.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Шрифты и UI**: `google_fonts` (Outfit), `shimmer`, `fl_chart`, `lottie`

### Backend & Cloud
- **База данных**: [Firebase Firestore](https://firebase.google.com/docs/firestore)
- **Аутентификация**: Firebase Auth (Email/Pass, Google Sign-In, Гостевой вход)
- **Уведомления**: Firebase Cloud Messaging (FCM) + `flutter_local_notifications`
- **Аналитика и конфиги**: Firebase Remote Config
- **Серверная логика**: Dart Shelf (задеплоен на Render)

---

## 🏗️ Структура проекта

```text
lib/
├── main.dart                 # Точка входа в приложение
├── l10n/                     # Файлы локализации (ARBs)
├── models/                   # Dart-модели данных (User, University, Notification)
├── screens/                  # Экраны (UI слои)
│   ├── ai_consultant_screen.dart
│   ├── home_screen.dart
│   ├── paywall_screen.dart   # Подписки TANDAU+
│   └── ...
├── services/                 # Бизнес-логика (Auth, Notifications, AI, Firestore)
├── theme/                    # Дизайн система (AppColors, AppTheme)
└── widgets/                  # Переиспользуемые UI компоненты
```

---

## 🚀 Как запустить локально

### 1. Предварительные требования
- Установленный [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Настроенный Android Studio / VS Code с плагинами Flutter и Dart
- Подключенное физическое устройство или запущенный эмулятор

### 2. Клонирование и установка зависимостей
```bash
# Клонирование репозитория
git clone https://github.com/Kriazer078/TANDAU.git
cd TANDAU

# Загрузка пакетов
flutter pub get
```

### 3. Запуск приложения
```bash
# Обычный запуск в debug-режиме
flutter run
```

---

## 👨‍💻 Авторы и контрибьюторы

Проект разработан командой стартапа **TANDAU**.
*Миссия: Сделать высшее образование доступным, а процесс выбора университета — понятным и технологичным.*

---
<div align="center">
  <p>Сделано с ❤️ в Казахстане</p>
</div>
