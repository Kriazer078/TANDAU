<div align="center">

# 🎓 TANDAU

### Навигатор по университетам Казахстана

*Помогаем абитуриентам найти свой идеальный вуз и получить образовательный грант*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
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

<table>
<tr>
<td width="50%">

### 📊 Алгоритм 4-х вузов (СВД)
Расчёт шансов на грант по каждому вузу на основе актуальных данных МОН РК с пояснением методологии

### 🤖 AI-Консультант
Персональные рекомендации по поступлению, анализ профиля и генерация стратегий с помощью нейросети

### 🏫 Каталог 50+ вузов
Подробная информация о вузах с контактами, специальностями и отзывами студентов

</td>
<td width="50%">

### ⚖️ Сравнение вузов
Удобное сравнение университетов по ключевым параметрам

### 🌍 Мультиязычность
Поддержка русского, казахского и английского языков

### 🌙 Тёмная тема
Стильный тёмный режим по умолчанию для комфортного использования

</td>
</tr>
</table>

---

## 🛠 Технологии

<div align="center">

| Категория | Технология | Назначение |
|:---------:|:----------:|:----------:|
| 📱 Frontend | **Flutter / Dart** | Кроссплатформенный UI |
| ⚙️ Backend | **Dart Shelf** | API-сервер на Render |
| 🗄 База данных | **Firestore** | Хранение данных |
| 🔐 Авторизация | **Firebase Auth** | Google, Apple, Email |
| 🧠 AI | **Google Gemini** | Интеллектуальный консультант |
| 📬 Уведомления | **FCM** | Push-нотификации |
| 📸 Хранилище | **ImgBB** | Загрузка фотографий |

</div>

---

## 🚀 Быстрый старт

### Требования
- Flutter 3.x+
- Dart SDK 3.10+
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
| 📄 | [Политика конфиденциальности](https://tandau-backend.onrender.com/privacy) |
| 🗑 | [Удаление аккаунта](https://tandau-backend.onrender.com/delete-account) |

</div>

---

<div align="center">

### 🇰🇿 Сделано в Казахстане с ❤️

**© 2026 TANDAU. Все права защищены.**

</div>
