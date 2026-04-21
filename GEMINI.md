# AGENTS Guide for TANDAU App

*This document is consumed by autonomous coding agents (OpenCode, Cursor, Copilot, etc.) to understand how to build, test, lint, and style the codebase.*

---

## Project Overview
- **Framework**: Flutter 3.x (Dart 3.10.8+)
- **Target platforms**: Android, iOS, Web, macOS, Windows
- **Main entry point**: `lib/main.dart`
- **Backend**: Dart Shelf server in `backend_dart/` folder (deployed at tandau-backend-60478017512.europe-west1.run.app)
- **Tests**: `test/` (widget tests)
- **State Management**: flutter_riverpod + ValueNotifier
- **Internationalization**: 3 locales (Russian default, Kazakh, English) via `lib/l10n/`

---

## Build / Run Commands
| Goal | Command | Notes |
|------|---------|-------|
| Install dependencies | `flutter pub get` | Run after cloning or `pubspec.yaml` changes |
| Run app (hot-reload) | `flutter run` | Default runs on first connected device |
| Run on specific device | `flutter run -d <device-id>` | Use `flutter devices` to list IDs |
| Build Android APK (debug) | `flutter build apk --debug` |
| Build Android APK (release) | `flutter build apk --release` |
| Build iOS (macOS only) | `flutter build ios --release` |
| Build Web | `flutter build web` |
| Build Windows | `flutter build windows` |
| Run Dart backend locally | `cd backend_dart && dart pub get && dart run bin/server.dart` |

---

## Test Commands
- **Run all tests**: `flutter test`
- **Run a single test file**: `flutter test test/widget_test.dart`
- **Run tests matching a name**: `flutter test --name "MyWidget"`
- **Watch mode**: `flutter test --watch`
- **Coverage**: `flutter test --coverage && genhtml coverage/lcov.info -o coverage/html`

---

## Lint & Static Analysis
| Tool | Command | Description |
|------|---------|-------------|
| Dart Analyzer | `flutter analyze` | Checks for type errors, dead code, etc. |
| Format code | `dart format .` | Auto-formats all Dart files |
| Check formatting (CI) | `dart format --set-exit-if-changed .` |
| Run all checks | `dart format --set-exit-if-changed . && flutter analyze && flutter test` |

---

## Code-Style Guidelines

The project follows **Effective Dart** style with project-specific conventions.

### General Principles
1. **Consistency** – Use `dart format` as the single source of truth.
2. **Readability** – Prefer expressive names over terse abbreviations.
3. **Safety** – Use non-nullable types; leverage null-safety.
4. **Performance** – Keep widget builds pure; use `RepaintBoundary` for list items.

### Naming Conventions
- **Classes / Enums / Mixins**: `PascalCase` (e.g., `UserModel`, `AuthService`)
- **Constants**: `camelCase` with `const` (e.g., `const maxAttempts = 5;`)
- **Variables / Fields**: `camelCase` (e.g., `currentUser`, `isLoggedIn`)
- **Private members**: underscore prefix (`_auth`, `_firestore`, `_isRegistering`)
- **Functions / Methods**: `camelCase` (e.g., `loadUserData`, `signInWithGoogle`)
- **Widget classes**: descriptive names (e.g., `UniversityCard`, `SplashScreen`)
- **Test files**: end with `_test.dart`

### Imports
Package imports first, then relative imports, separated by blank lines:
```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'auth_service.dart';
```
- Sort alphabetically within each group.
- Prefer relative imports for project files.

### Formatting
- **Line length**: 80 characters (formatter wraps automatically).
- **Trailing commas**: Always in multiline collections and parameter lists.
- **Blank lines**: One blank line between class members, two before top-level declarations.

### Types & Null-Safety
- Declare explicit types for public APIs.
- Prefer non-nullable fields with `required` constructors.
- Use `late` only when initialization is guaranteed before first use.
- Nullable fields should have clear `?` suffix and be documented.

### Error Handling
- Use `try/catch` around code that can throw (network, Firebase APIs).
- Log errors with `debugPrint()` for debugging (not `print()`).
- Preserve stack traces when rethrowing: `catch (e, stack) { debugPrint('$e'); rethrow; }`
- Return error messages as strings from service methods (e.g., `Future<String?> login()` returns null on success).
- Use `.timeout()` on async operations to prevent hanging.

### Service Pattern
Services use the Singleton pattern:
```dart
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
}
```
- Use `ValueNotifier<T>` for reactive state that widgets can listen to.
- Initialize services in `main.dart` before `runApp()`.

### Widget Best Practices
- Keep `build` methods pure – no side effects, no async work.
- Use `const` constructors wherever possible.
- Extract reusable widgets to `lib/widgets/`.
- Use `RepaintBoundary` for items in scrollable lists.
- Theme access: `Theme.of(context)` or `AppColors` constants.
- Cache images with `memCacheWidth`/`memCacheHeight` for performance.

### Documentation
- Use `///` for public API documentation.
- Add brief comments for complex logic.
- Emoji-prefixed comments for visual scanning (e.g., `// 🔐`, `// ⭐`, `// 🚫`).

### Testing Guidelines
- Use `testWidgets` for widget tests.
- Arrange-Act-Assert pattern.
- Name tests descriptively: `testWidgets('TANDAU app smoke test', ...)`

---

## Project-Specific Rules

### Backend (Dart Shelf)
- Located in `backend_dart/` folder.
- Uses `shelf` and `shelf_router` packages.
- Run with `dart run bin/server.dart`.
- Environment variables loaded from `.env` file.

### Internationalization (l10n)
- ARB files in `lib/l10n/` (app_en.arb, app_ru.arb, app_kk.arb).
- Generated localizations in `app_localizations_*.dart`.
- Default locale: Russian (`ru`).

### Firebase Integration
- Firebase initialized in `main.dart` with `Firebase.initializeApp()`.
- Uses: `firebase_auth`, `cloud_firestore`, `firebase_messaging`, `firebase_storage`, `firebase_remote_config`.
- User data stored in `users` collection.

---

## References
- [Effective Dart: Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Shelf Package](https://pub.dev/packages/shelf)

---

*End of AGENTS.md – keep this file up-to-date as the project evolves.*
