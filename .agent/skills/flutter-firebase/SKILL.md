---
name: flutter-firebase
description: Specialized coding assistant for Flutter & Firebase development. Use this skill for tasks involving UI implementation, state management (Riverpod/Bloc), Firestore data modeling, Authentication flows, and Cloud Functions.
---

# Flutter & Firebase Architecture Skill

## Overview
This skill embodies the role of a Senior Flutter & Firebase Architect. It provides guidelines, patterns, and safety checks for developing the TANDAU - Talent Analysis & Navigation for Dream University application.

## Core Principles

1.  **Safety First**:
    *   ALWAYS check for `null` safety.
    *   Prevent data leaks; validate user permissions (Firestore Rules).
2.  **Clean Architecture**:
    *   Strict separation of Business Logic (BLoC/Riverpod) from UI (Widgets).
    *   Service layer for all Firebase interactions.
3.  **Error Handling**:
    *   Wrap ALL network requests in `try-catch`.
    *   Provide user-friendly error messages (not raw socket exceptions).
4.  **No Breaking Changes**:
    *   When adding features, ensure backward compatibility with existing data models.

## Tech Stack & Standards

*   **Framework**: Flutter (Dart)
*   **Backend**: Firebase (Auth, Firestore, Functions, Storage)
*   **State Management**: Riverpod (preferred) or BLoC. *CHECK existing context before implementing.*
*   **Styling**:
    *   Use `app_theme.dart` and `app_colors.dart` for consistency.
    *   Avoid hardcoded colors/sizes in widgets; use constants.

## Common Workflows

### 1. Creating a New Feature
1.  **Model**: Define data class with `freezed` or `json_serializable`.
2.  **Repository**: Create a service class for Firestore CRUD operations.
3.  **State**: Create a Provider/Bloc to manage the UI state.
4.  **UI**: Build the widget, listening to the state provider.

### 2. Firebase Integration
*   **Auth**: Use `FirebaseAuth` instances via a provider. Handle `authStateChanges`.
*   **Firestore**:
    *   Use `withConverter` for type-safe data handling.
    *   Always handle `offline` states if necessary.

## Checklist Before Committing
*   [ ] Are all variables typed (no `dynamic` unless absolutely necessary)?
*   [ ] Are imports optimized?
*   [ ] Is there a `try-catch` block around Firebase calls?
*   [ ] Does the UI handle "Loading", "Error", and "Empty" states?
