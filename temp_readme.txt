<div align="center">

<img src="assets/images/icon.jpg" alt="TANDAU Logo" width="120" style="border-radius: 20px; box-shadow: 0 8px 24px rgba(0,0,0,0.1);"/>

# TANDAU

**Talent Analysis & Navigation for Dream University**

*AI-навигатор, который превращает хаос поступления в понятный пошаговый план к образовательному гранту.*

[![Flutter](https://img.shields.io/badge/Flutter-3.10-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Gemini AI](https://img.shields.io/badge/AI-Google_Gemini-8E75B2?style=flat-square&logo=google-gemini&logoColor=white)](https://ai.google.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)

**[Скачать приложение](#-скачать)** • **[Tech Stack](#-tech-stack)** • **[Roadmap](#-roadmap)**

</div>

---

## 🎯 Миссия
Каждый год сотни тысяч абитуриентов в Казахстане теряются в сложном процессе выбора университета. **TANDAU** решает эту проблему, объединяя актуальные данные МОН РК и мощь искусственного интеллекта в удобном мобильном приложении. Мы делаем качественное высшее образование доступным.

## ✨ Ключевые возможности

🚀 **AI-Оценка шансов на грант**
Алгоритм СВД, совмещенный с аналитикой прошлых лет. Вводите баллы ЕНТ — получаете точный расчет вероятности поступления по 4 вузам на одном экране.

🧠 **Умный AI-Консультант (Gemini 1.5 Pro)**
Ваш персональный ментор, который знает всё о ГОП, квотах и дедлайнах. Поддерживает потоковую генерацию ответов (SSE) и контекст диалога на 3-х языках (RU, KZ, EN).

🏫 **Офлайн-каталог 50+ вузов**
Вся база топовых вузов с проходными баллами, стоимостью обучения и живыми отзывами. Находите идеальный университет и сравнивайте фаворитов свайпом.

⚡ **Молниеносная производительность**
Архитектура на основе Riverpod, умное кэширование и точечные микро-анимации. Приложение работает плавно с 60 FPS даже на слабых устройствах.

---

## 🛠 Tech Stack

TANDAU — это современный продукт, отвечающий высоким стандартам разработки:

- **Frontend:** Flutter / Dart 3.10 (Riverpod, Custom Design System, Glassmorphism)
- **Backend:** Собственный Dart Shelf микросервис (задеплоен на Render)
- **Инфраструктура & БД:** Firebase (Firestore, Auth, Cloud Messaging, Remote Config)
- **ИИ-Ядро:** Google Gemini API (Stream generate с поддержкой Google Search Grounding)

---

## 🚀 Быстрый старт (Для разработчиков)

```bash
# 1. Клон репозитория
git clone https://github.com/Kriazer078/TANDAU.git
cd TANDAU

# 2. Установка зависимостей
flutter pub get

# 3. Генерация локализации
flutter gen-l10n

# 4. Запуск проекта
flutter run
```

*Для локального тестирования AI-бэкенда:*
```bash
cd backend_dart
dart run bin/server.dart
```

---

## 📥 Скачать

Готовые релизные сборки (APK) всегда доступны в разделе **[Releases](../../releases)** на GitHub. 
Продакшн бэкенд развернут в облаке и подключается автоматически.

---

## 🗺 Roadmap

- [x] Релиз калькулятора грантов (база МОН РК)
- [x] Интеграция умного Gemini AI Консультанта
- [x] Оффлайн-Каталог и модуль сравнения вузов
- [x] Мультиязычность (Казахский, Русский, Английский)
- [ ] 🚀 **Публикация в Google Play (Q3)**
- [ ] 🍏 **Релиз iOS версии в App Store (Q4)**
- [ ] 🧠 **Внедрение ML-модели для персональных рекомендаций**

---

<div align="center">

### Сделано в Казахстане 🇰🇿 

**© 2026 TANDAU**  
По вопросам сотрудничества: [tandau.app.help@gmail.com](mailto:tandau.app.help@gmail.com)

</div>�ся в коде** |
| 🔐 | Пароли хранятся в зашифрованном виде |
| 🗑 | Полное **удаление аккаунта** и всех данных пользователя |
| 🧹 | Антимат модерация на 3 языках (RU, KZ, EN) |
| ✅ | Соответствие требованиям Google Play к ИИ-продуктам |

---

## 📁 Структура проекта

```
tandau/
├── lib/
│   ├── main.dart              # Точка входа
│   ├── models/                # Модели данных
│   ├── services/              # Бизнес-логика (Singletons)
│   ├── screens/               # Экраны приложения
│   ├── widgets/               # Переиспользуемые виджеты
│   └── l10n/                  # Локализация (RU, KZ, EN)
├── backend_dart/              # Dart Shelf API сервер
├── test/                      # Widget & Unit тесты
├── docs/                      # Документация
├── assets/images/             # Иконки и изображения
└── firebase.json              # Firebase конфигурация
```

---

## 📋 Полезные ссылки

<div align="center">

| | Ссылка |
|:-:|:------:|
| 📄 | [Политика конфиденциальности](https://tandau-app.web.app/privacy_policy.html) |
| 🗑 | [Удаление аккаунта](https://tandau-backend.onrender.com/delete-account) |
| 📧 | [Email поддержки](mailto:tandau.app.help@gmail.com) |

</div>

---

## 🗺 Roadmap

- [x] Калькулятор грантов (СВД)
- [x] Умный 3-шаговый подбор грантов (по ГОП 2025/2026)
- [x] AI-Консультант с историей чатов
- [x] Каталог 50+ вузов с кэшированием
- [x] Сравнение вузов и дедлайны
- [x] Мультиязычность (RU, KZ, EN)
- [x] Потоковые ответы AI (SSE)
- [ ] 🔜 Публикация в Google Play
- [ ] 🔜 iOS версия в App Store
- [ ] 🔜 Рекомендательная система на ML

---

<div align="center">

### 🇰🇿 Сделано в Казахстане с ❤️

**© 2026 TANDAU** · *Talent Analysis & Navigation for Dream University*

**v1.2.5** · [tandau.app.help@gmail.com](mailto:tandau.app.help@gmail.com)

</div>
