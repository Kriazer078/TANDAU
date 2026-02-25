# TANDAU

Навигатор по университетам Казахстана. Помогает абитуриентам оценить шансы на грант и выбрать вуз.

## Стек

- Flutter / Dart
- Firebase (Auth, Firestore, FCM, Storage)
- Dart Shelf backend (Render)
- Google Gemini API
- RevenueCat

## Запуск

```bash
flutter pub get
flutter run
```

Backend:

```bash
cd backend_dart
dart pub get
dart run bin/server.dart
```

## Сборка

```bash
flutter build appbundle --release --dart-define=IMGBB_API_KEY=<key>
```

## Ссылки

- [Политика конфиденциальности](https://tandau-backend.onrender.com/privacy)
- [Удаление аккаунта](https://tandau-backend.onrender.com/delete-account)
