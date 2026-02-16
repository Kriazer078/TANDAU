# Flutter Clean Architecture with Riverpod & Firebase

## Layer Structure

### 1. Domain Layer (Entities & Layouts)
*   **Models**: Pure Dart classes. Use `freezed` for immutability.
    ```dart
    @freezed
    class User methods ...
    ```

### 2. Data Layer (Repositories)
*   **Repositories**: Interface with Firestore/Auth.
*   **Code Pattern**:
    ```dart
    final authRepositoryProvider = Provider((ref) => AuthRepository(Firebase.auth));

    class AuthRepository {
      final FirebaseAuth _auth;
      AuthRepository(this._auth);

      Future<void> signIn(...) async {
        try { ... } catch (e) { throw CustomException(e); }
      }
    }
    ```

### 3. Application Layer (State Management)
*   **Providers**: Use `StateNotifierProvider` or `AsyncNotifierProvider` (Riverpod 2.0+).
    ```dart
    final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(authRepository: ref.watch(authRepositoryProvider));
    });
    ```

### 4. Presentation Layer (UI)
*   **Widgets**: Dumb components that consume state.
    ```dart
    class LoginScreen extends ConsumerWidget {
      @override
      Widget build(BuildContext context, WidgetRef ref) {
        final state = ref.watch(authControllerProvider);
        return state.isLoading ? Loader() : Scaffold(...);
      }
    }
    ```
