<div align="center">

# 🎓 TANDAU

### Навигатор по университетам Казахстана

*Помогаем абитуриентам найти свой идеальный вуз и получить образовательный грант*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Gemini_AI-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge)]()

---

</div>

## 🌟 О проекте

**TANDAU** — мобильное приложение, которое помогает абитуриентам Казахстана оценить шансы на образовательный грант, подобрать подходящий вуз и получить персональную стратегию поступления с помощью искусственного интеллекта.

> 💡 Название **TANDAU** (каз. «ТАҢДАУ») означает **«Выбор»** — мы помогаем сделать правильный выбор.

---

## ✨ Возможности

### 📊 Алгоритм 4-х вузов (СВД)
Расчёт шансов на грант по каждому вузу на основе актуальных открытых данных МОН РК и пороговых баллов прошлых лет. Максимальная прозрачность алгоритма.

### 🤖 AI-Консультант с Историей (Gemini)
Персональные стратегии поступления с помощью нейросети Google Gemini. Поддержка механизма обратной связи (Лайки/Дизлайки), встроенной антимат модерации на 3 языках и **сохранения истории чатов** (как в ChatGPT) для быстрого доступа к прошлым консультациям без лагов.

### 🏫 Каталог 50+ вузов
Подробная база данных об университетах Казахстана (стоимость, проходные баллы, контакты, отзывы) с кэшированием данных для оффлайн доступа.

### ⚡ Высокая производительность и Плавный UI
Приложение оптимизировано для работы без "микро-лагов": кэширование списков, точечные `ValueNotifier` вместо полного перестроения экранов в поиске и быстрые анимации.

### ⚖️ Сравнение и Дедлайны
Сравнение до 2-х вузов на одном экране. Встроенный календарь актуальных дедлайнов поступления (ЕНТ, Гранты 2026).

### 🌍 Мультиязычность
Полная поддержка русского, казахского и английского языков (через `.arb` файлы Flutter l10n).

### 🛡️ Стабильность и Безопасность
Полноценное тестирование (Unit/Widget Tests), обработка крашей системы и Firebase защита данных. Соответствие требованиям Google Play к ИИ-продуктам.

---

## 🛠 Технологии

<div align="center">

| Категория | Технология | Назначение |
|:---------:|:----------:|:----------:|
| 📱 Frontend | **Flutter / Dart** | Кроссплатформенный UI |
| ⚙️ Backend | **Dart Shelf** | API-сервер на Render |
| 🗄 База данных | **Firestore** | Хранение данных, История чатов |
| 🔐 Авторизация | **Firebase Auth** | Google, Apple, Email |
| 🧠 AI | **Google Gemini** | Интеллектуальный консультант |
| 📬 Уведомления | **FCM** | Push-нотификации |
| 🌍 Хостинг | **Firebase Hosting** | Лендинг и Политика конфиденциальности |

</div>

---

## 🚀 Быстрый старт

### Требования
- Flutter 3.x+
- Dart SDK >=3.0.0 <4.0.0
- Firebase проект
- Android Studio / VS Code

### Установка

```bash
# 1. Клонируйте репозиторий
git clone https://github.com/Kriazer078/TANDAU.git
cd TANDAU

# 2. Установите зависимости
flutter pub get

# 3. Запустите приложение
flutter run
```

### Backend

```bash
cd backend_dart
dart pub get
dart run bin/server.dart
```

---

## 📦 Сборка

```bash
# 📱 APK (для установки на телефон)
flutter build apk --release --dart-define=IMGBB_API_KEY=<your_key>

# 📦 App Bundle (для Google Play)
flutter build appbundle --release --dart-define=IMGBB_API_KEY=<your_key>
```

---

## 🔒 Безопасность

- 🛡 Данные защищены **Firebase Authentication** и **Firestore Security Rules**
- 🔑 API-ключи передаются через `--dart-define` — не хранятся в коде
- 🔐 Пароли хранятся в зашифрованном виде
- 🗑 Полное удаление аккаунта и всех данных пользователя

---

## 📋 Полезные ссылки

<div align="center">

| | Ссылка |
|:-:|:------:|
| 📄 | [Политика конфиденциальности](https://tandau-app.web.app/privacy_policy.html) |
| 🗑 | [Удаление аккаунта](https://tandau-backend.onrender.com/delete-account) |

</div>

---

## 📞 Поддержка

По любым вопросам, предложениям или проблемам:

📧 Email: **tandau.app.help@gmail.com**

---

<div align="center">

### 🇰🇿 Сделано в Казахстане с ❤️

**© 2026 TANDAU. Все права защищены.**

</div>
