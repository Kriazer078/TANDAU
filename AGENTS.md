# 📋 AGENTS Guide for TANDAU App

*This document is consumed by autonomous coding agents (OpenCode, Cursor, Copilot, etc.) to understand how to build, test, lint, and style the codebase.*

---

## 📦 Project Overview
- **Framework**: Flutter 3.x (Dart 3.x)
- **Target platforms**: Android, iOS, Web, macOS, Windows
- **Main entry point**: `lib/main.dart`
- **Backend**: Firebase (functions in `functions/` folder)
- **Tests**: `test/` (widget tests, unit tests)
- **CI**: GitHub Actions (not shown here, but uses `flutter test` and `flutter build`)

---

## 🛠️ Build / Run Commands
| Goal | Command | Notes |
|------|---------|-------|
| Install dependencies (Flutter/Dart) | `flutter pub get` | Must be run after cloning or after `pubspec.yaml` changes |
| Run app (hot‑reload) on attached device/emulator | `flutter run` | Default runs on the first connected device |
| Run on specific device | `flutter run -d <device-id>` | Use `flutter devices` to list IDs |
| Build Android APK (debug) | `flutter build apk --debug` |
| Build Android APK (release) | `flutter build apk --release` |
| Build iOS app (requires macOS) | `flutter build ios --release` |
| Build Web app | `flutter build web` |
| Build macOS app | `flutter build macos` |
| Build Windows app | `flutter build windows` |
| Run Firebase Functions locally | `cd functions && npm install && npm run serve` |
| Deploy Firebase Functions | `cd functions && npm run deploy` |

---

## ✅ Test Commands
- **Run all tests**: `flutter test`
- **Run a single test file**: `flutter test test/widget_test.dart`
- **Run a specific test case** (using pattern): `flutter test -run-test "MyWidget renders correctly"`
- **Watch mode** (re‑run on file change): `flutter test --watch`
- **Coverage**: `flutter test --coverage && genhtml coverage/lcov.info -o coverage/html`

---

## 🔍 Lint & Static Analysis
| Tool | Command | Description |
|------|---------|-------------|
| Dart Analyzer | `flutter analyze` | Checks for type errors, dead code, etc. |
| Custom Lint Rules (if any) | `flutter analyze --fatal-infos` | Treats info‑level warnings as errors |
| Format code | `dart format .` or `flutter format .` |
| Check formatting (CI) | `dart format --set-exit-if-changed .` |
| Run all checks (CI style) | `flutter format --set-exit-if-changed . && flutter analyze && flutter test` |

---

## 🧭 Code‑Style Guidelines
The team follows the **Effective Dart** style guide with a few project‑specific tweaks.

### General Principles
1. **Consistency** – Use the same formatting everywhere. `dart format` is the single source of truth.
2. **Readability** – Prefer expressive names over terse abbreviations.
3. **Safety** – Use non‑nullable types whenever possible; opt‑in to null‑safety (already default).
4. **Performance** – Avoid unnecessary `async`/`await` nesting; keep widget builds cheap.

### Naming Conventions
- **Classes / Enums / Mixins**: `PascalCase` (e.g., `UserProfile`, `ThemeMode`)
- **Constants**: `camelCase` with `const` keyword (e.g., `const apiBaseUrl = "...";`)
- **Variables / Fields**: `camelCase` (e.g., `selectedIndex`)
- **Private members**: start with underscore (`_internalCache`).
- **Functions / Methods**: `camelCase` (e.g., `fetchUserData`).
- **Async functions**: suffix with `Async` when the return type is `Future` and the name isn’t already a verb phrase (e.g., `loadPreferencesAsync`).
- **Widget classes**: end with `Widget` only when it clarifies intent (e.g., `LoginButton`).
- **Test files**: end with `_test.dart` (already the case).

### Imports
- **Package imports** first, then **relative imports**, each group separated by a blank line.
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import 'widgets/custom_button.dart';
```
- Sort alphabetically within each group.
- Use **export** in barrel files (`lib/src/widgets.dart`) to simplify imports.
- Prefer **show/hide** to limit namespace pollution when a file imports many symbols.

### Formatting
- **Line length**: 80 characters (the formatter will wrap automatically).
- **Trailing commas**: always add trailing commas in multiline collections and parameter lists to enable automatic formatting.
- **Blank lines**: two blank lines before a top‑level declaration, one blank line between members inside a class.
- **Spaces**: one space after commas, around operators, after `if`, `for`, `while` keywords (`if (condition) {`).

### Types & Null‑Safety
- Declare explicit types; avoid `var` when the type isn’t obvious.
- Prefer **non‑nullable** fields with required constructors.
- Use `required` named parameters for mandatory values.
- When a nullable value is truly optional, document why it may be `null`.
- Use **late** only when you can guarantee initialization before first use.

### Error Handling
- Use **try/catch** only around code that can throw (e.g., network calls, Firebase APIs).
- Preserve stack traces: `catch (e, stack) { logError(e, stack); rethrow; }`
- Convert low‑level exceptions to domain‑specific ones where appropriate (e.g., `NetworkException`).
- For async streams, use `await for` with proper cancellation handling.
- UI‑level errors should be surfaced via `ScaffoldMessenger` or a dedicated error widget.

### Widget Best Practices
- Keep `build` methods **pure** – no side effects, no async work.
- Extract large widget trees into private helper widgets or methods.
- Use `const` constructors whenever possible.
- Prefer **Provider** / **Riverpod** for state management; avoid `setState` for global state.
- Document public widget APIs with Dartdoc comments.

### Documentation (Dartdoc)
- Every public class, method, and top‑level function must have a brief description.
- Use markdown inside comments for lists, code examples.
- Example:
```dart
/// Returns a formatted greeting.
///
/// ```dart
/// final msg = greetUser(name: 'Alex');
/// ```
String greetUser({required String name}) => 'Hello $name!';
```

### Testing Guidelines
- **Arrange‑Act‑Assert** pattern for all tests.
- Use `testWidgets` for widget tests; mock dependencies with `mockito` or `mocktail`.
- Keep test files small – one logical unit per file.
- Name tests clearly: `test('LoginScreen shows error when credentials are invalid', () { … })`.
- Ensure coverage ≥ 80 % for new code (CI will fail otherwise).

---

## 🗂️ Project‑Specific Rules
### Firebase Functions (Node.js)
- Lint with `npm run lint` (uses ESLint + Prettier).
- Follow **Airbnb** style guide, except prefer `singleQuote: true`.
- Use **async/await**; avoid callbacks.
- All exported functions must have JSDoc comments.

### .cursor Rules (if present)
> *No `.cursor` directory detected in the repository; agents should fall back to the generic guidelines above.*

### Copilot Instructions
> *No `.github/copilot-instructions.md` file detected; default Copilot behaviour applies.*

---

## 📚 References
- [Effective Dart: Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Functions Guides](https://firebase.google.com/docs/functions)
- [GitHub Actions – Flutter CI](https://github.com/marketplace/actions/flutter-action)

---

*End of AGENTS.md – keep this file up‑to‑date as the project evolves.*
