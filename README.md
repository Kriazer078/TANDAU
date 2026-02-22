<div align="center">
  <img src="assets/images/icon.jpg" width="150" height="150" alt="TANDAU Logo">
  
  <h1>🌟 TANDAU</h1>
  <p><strong>Talent Analysis & Navigation for Dream University</strong></p>
  <p><em>Инновационный навигатор для абитуриентов Казахстана, помогающий уверенно выбрать университет мечты и оценить шансы на грант.</em></p>

  <p>
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
    <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
    <a href="https://firebase.google.com/"><img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=white" alt="Firebase"></a>
    <a href="https://riverpod.dev/"><img src="https://img.shields.io/badge/State_Management-Riverpod-1A1A1A?style=for-the-badge&logo=dart&logoColor=white" alt="Riverpod"></a>
  </p>

  <h3>🚀 <a href="https://github.com/Kriazer078/TANDAU/releases/latest/download/app-release.apk">Скачать приложение TANDAU (Android APK)</a></h3>
</div>

---

## ✨ Ключевые возможности

### 🎓 **Умный подбор вузов**
Находите идеальные программы по городу, специальности, стоимости обучения и проходным баллам. Детальная информация по каждому университету: наличие общежитий, грантов и сроки приема документов.

### 🤖 **AI-Консультант уровня Tech-Startup (Алгоритм 4-х вузов)**
Интегрированный искусственный интеллект (Gemini AI), выступающий в роли элитного стратегического советника. Он генерирует персонализированную стратегию поступления на грант, оценивает ваши шансы, учитывая тренды IT-рынка и государственные программы (Серпін, квоты), и предлагает 4 запасных варианта. Вы получаете по **1000 бесплатных AI-запросов каждый день**!

### 🛡️ **Система подписок TANDAU+**
Многоуровневый доступ к функциям: **Basic** (1000 запросов/день), **PRO** и **Premium**, открывающие приоритетную глубокую аналитику и отсутствие рекламы.

### 📱 **Пользовательский опыт:**
- 🌍 **Мультиязычность**: Поддержка казахского, русского и английского языков.
- 🌙 **Адаптивный дизайн**: Современный премиум интерфейс (Material 3) с поддержкой светлой и темной тем.
- ❤️ **Избранное**: Сохраняйте интересующие вузы для быстрого доступа.

---

## 🛠️ Технологический стек

| Frontend | Backend & Cloud |
| :--- | :--- |
| **Framework**: [Flutter](https://flutter.dev/) | **База данных**: [Firebase Firestore](https://firebase.google.com/docs/firestore) |
| **Язык**: [Dart](https://dart.dev/) | **Аутентификация**: Firebase Auth (Email, Google, Guest) |
| **State Management**: [Riverpod](https://riverpod.dev/) | **Уведомления**: Firebase Cloud Messaging (FCM) |
| **UI/UX**: `google_fonts`, `shimmer`, `fl_chart`, `lottie` | **Серверная логика**: Dart Shelf (задеплоен на Render) |

---

## 🏗️ Структура проекта

```text
lib/
├── main.dart                 # Точка входа в приложение
├── l10n/                     # Файлы локализации (ARBs: ru, kk, en)
├── models/                   # Dart-модели данных (User, University)
├── screens/                  # Экраны (UI слои)
│   ├── ai_consultant_screen.dart
│   ├── home_screen.dart
│   ├── paywall_screen.dart   # Подписки TANDAU+
│   └── ...
├── services/                 # Бизнес-логика (Auth, FCM, AI, Firestore)
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
