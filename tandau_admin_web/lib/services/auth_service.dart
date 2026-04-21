import 'package:flutter/material.dart';
import 'dart:async'; // Import async for TimeoutException
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

import 'package:shared_preferences/shared_preferences.dart'; // Import for persistent attempts
import 'dart:io'; // ⭐ Import File
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'notification_service.dart';
import '../models/user_model.dart';

import 'moderation_service.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  final ModerationService _moderationService = ModerationService();

  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  final ValueNotifier<UserModel?> currentUser = ValueNotifier<UserModel?>(null);
  bool _isRegistering =
      false; // Flag to prevent listener conflicts during registration

  // 🔐 Guard against double init() — store subscription to cancel on re-init
  StreamSubscription<User?>? _authSubscription;

  // Constants for login limiting
  static const String _attemptsKey = 'login_attempts';
  static const String _lockoutTimeKey = 'lockout_time';
  static const int _maxAttempts = 5;
  static const int _lockoutDurationMinutes = 5;

  /// Special error code returned when user is banned
  static const String bannedErrorCode = 'account-banned';

  /// Initialize and check auth state
  Future<void> init() async {
    // ⚡ Cancel previous listener to prevent double-subscription
    await _authSubscription?.cancel();

    // ⚡ Ожидаем окончания инициализации состояния аутентификации от Firebase.
    // Сначала проверяем синхронное состояние (часто уже готово после Firebase.initializeApp).
    User? initialUser = _auth.currentUser;
    if (initialUser == null) {
      try {
        // Если null, даем Firebase время восстановить сессию из кэша.
        // Использование .first гарантирует, что мы получим начальное состояние (user или null).
        initialUser = await _auth.authStateChanges().first.timeout(
          const Duration(seconds: 2),
        );
      } catch (_) {
        initialUser = null; // Пользователь не авторизован или таймаут
      }
    }
    if (initialUser != null) {
      debugPrint(
        '🟢 AUTH INIT: Обнаружен кэшированный пользователь (${initialUser.uid})',
      );
      if (initialUser.isAnonymous) {
        currentUser.value = UserModel(
          uid: initialUser.uid,
          name: 'Гость',
          email: 'guest@tandau.app',
          createdAt: DateTime.now(),
        );
        // Гостю данные загружать не нужно
        isLoggedIn.value = true;
      } else {
        await _loadUserData(initialUser.uid);
        if (bannedReason.value == null) {
          if (hasAdminAccess) {
            isLoggedIn.value = true;
          } else {
            debugPrint('🔴 AUTH INIT: Недостаточно прав, выходим.');
            await _auth.signOut();
            isLoggedIn.value = false;
            currentUser.value = null;
          }
        }
      }
    } else {
      debugPrint('🔴 AUTH INIT: Пользователь не обнаружен в кэше');
      isLoggedIn.value = false;
      currentUser.value = null;
    }

    // Слушаем последующие изменения (если токен обновился, логаут, etc.)
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      if (_isRegistering) {
        debugPrint(
          '🟡 AUTH: Состояние изменилось, но мы в процессе регистрации. Игнорируем.',
        );
        return;
      }
      if (user != null) {
        if (user.isAnonymous) {
          currentUser.value = UserModel(
            uid: user.uid,
            name: 'Гость',
            email: 'guest@tandau.app',
            createdAt: DateTime.now(),
          );
          isLoggedIn.value = true;
        } else {
          // Запрашиваем данные только если это новый пользователь (избегаем дублирования с init)
          if (currentUser.value?.uid != user.uid) {
            debugPrint(
              '🟢 AUTH: Новый пользователь обнаружен в Stream (${user.uid}). Загрузка...',
            );
            await _loadUserData(user.uid);
          }
          // Only mark as logged in if NOT banned AND has admin access
          if (bannedReason.value == null) {
            if (hasAdminAccess) {
              isLoggedIn.value = true;
            } else {
              debugPrint('🔴 AUTH STREAM: Недостаточно прав, выходим.');
              await _auth.signOut();
              isLoggedIn.value = false;
              currentUser.value = null;
            }
          }
        }
      } else {
        isLoggedIn.value = false;
        currentUser.value = null;
      }
    });

    // ⚡ Важно: теперь init() заканчивает работу синхронно или сразу после
    // загрузки данных начального юзера, что нужно дляSplashScreen.
  }

  /// Ban info notifier — non-null when user is banned and forced to log out
  final ValueNotifier<String?> bannedReason = ValueNotifier<String?>(null);

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        final UserModel user = UserModel.fromDocument(doc);

        // 🚫 Check if user is banned
        if (user.banned) {
          debugPrint('🚫 User ${user.email} is BANNED: ${user.banReason}');
          bannedReason.value = user.banReason ?? 'Ваш аккаунт заблокирован';
          await _auth.signOut();
          currentUser.value = null;
          isLoggedIn.value = false;
          return;
        }
        currentUser.value = user;

        // 🛡️ Track session if admin/moderator
        if (hasAdminAccess) {
          _updateSessionInfo(user);
        }
      }
    } catch (e) {
      debugPrint(
        'Error loading user data (might be offline or permission denied): $e',
      );
      // 🛡️ FIX: If Firestore fails but Firebase Auth user exists,
      // keep them logged in to avoid re-registration loop.
      // The profile data may be stale, but the session is preserved.
    }
  }

  /// 🔄 Public method to refresh user data from Firestore.
  /// Call after profile updates (e.g. OnboardingWizard) to sync local state.
  Future<void> refreshUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    }
  }

  // Admin role is managed via Firestore only — no client-side auto-sync.

  /// Login with email and password
  /// Returns null on success, error message on failure
  Future<String?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check lockout status
    final lockoutTimeStr = prefs.getString(_lockoutTimeKey);
    if (lockoutTimeStr != null) {
      final lockoutTime = DateTime.parse(lockoutTimeStr);
      final difference = DateTime.now().difference(lockoutTime);

      if (difference.inMinutes < _lockoutDurationMinutes) {
        final remaining = _lockoutDurationMinutes - difference.inMinutes;
        return 'Слишком много попыток. Попробуйте через $remaining мин.';
      } else {
        // Lockout expired, reset attempts
        await prefs.remove(_lockoutTimeKey);
        await prefs.setInt(_attemptsKey, 0);
      }
    }

    try {
      final credential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Превышено время ожидания');
            },
          );

      if (credential.user != null) {
        // Success - reset attempts
        await prefs.setInt(_attemptsKey, 0);
        await prefs.remove(_lockoutTimeKey);

        // SECURITY: await ban check before returning success
        await _loadUserData(credential.user!.uid);

        // If user was banned, _loadUserData already signed out
        if (bannedReason.value != null) {
          return bannedErrorCode; // BannedScreen is triggered by listener in main.dart
        }

        if (!hasAdminAccess) {
          await _auth.signOut();
          currentUser.value = null;
          isLoggedIn.value = false;
          return 'Доступ запрещен. Нужны права администратора или модератора.';
        }

        // Save FCM Token
        NotificationService().getToken().then((token) {
          if (token != null) NotificationService().saveTokenToFirestore(token);
        });

        return null; // Success
      }
      return 'Ошибка входа';
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.code} - ${e.message}');

      // Increment attempts on failure
      int attempts = prefs.getInt(_attemptsKey) ?? 0;
      attempts++;
      await prefs.setInt(_attemptsKey, attempts);

      if (attempts >= _maxAttempts) {
        await prefs.setString(
          _lockoutTimeKey,
          DateTime.now().toIso8601String(),
        );
        return 'Превышено 5 попыток входа. Доступ заблокирован на 5 минут.';
      }

      return _getErrorMessage(e.code);
    } on TimeoutException {
      return 'Превышено время ожидания. Проверьте интернет.';
    } catch (e) {
      debugPrint('Login error: $e');
      return 'Произошла ошибка. Попробуйте позже';
    }
  }

  /// Sign In with Google
  /// Returns null on success, error message on failure
  Future<String?> signInWithGoogle() async {
    try {
      debugPrint('🚀 Starting Google Sign-In...');

      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      final UserCredential userCredential = await _auth.signInWithPopup(
        googleProvider,
      );
      final User? user = userCredential.user;

      if (user != null) {
        debugPrint('✅ Firebase Auth success: ${user.uid}');
        // 5. Check if user exists in Firestore (with timeout)
        try {
          final doc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 10));

          if (!doc.exists) {
            debugPrint('📝 Creating new user document in Firestore');
            // Create new user profile
            final userModel = UserModel(
              uid: user.uid,
              name: user.displayName ?? 'Google User',
              email: user.email ?? '',
              createdAt: DateTime.now(),
            );
            await _firestore
                .collection('users')
                .doc(user.uid)
                .set(userModel.toMap());

            // Track stats: New User via Google
            _trackNewUser();
          }
        } catch (e) {
          debugPrint(
            'Error checking user/creating user in Firestore (continuing): $e',
          );
        }

        // SECURITY: await ban check before returning success
        await _loadUserData(user.uid);

        // If user was banned, _loadUserData already signed out
        if (bannedReason.value != null) {
          return bannedErrorCode; // BannedScreen is triggered by listener in main.dart
        }

        if (!hasAdminAccess) {
          await _auth.signOut();
          currentUser.value = null;
          isLoggedIn.value = false;
          return 'Доступ запрещен. Нужны права администратора или модератора.';
        }

        // Save FCM Token
        NotificationService().getToken().then((token) {
          if (token != null) NotificationService().saveTokenToFirestore(token);
        });

        debugPrint('🎉 Google Sign-In complete!');
        return null; // Success
      }
      return 'Ошибка авторизации Firebase';
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Google Sign-In Firebase Error: ${e.code} - ${e.message}');
      return 'Ошибка Firebase: ${e.message}';
    } catch (e) {
      debugPrint('❌ Google Sign-In Unexpected Error: $e');
      if (e.toString().contains('sign_in_failed')) {
        return 'Ошибка конфигурации Google (SHA-1). Проверьте настройки Firebase.';
      }
      return 'Ошибка входа через Google. Попробуйте позже.';
    }
  }

  /// Check if username is unique
  /// Returns true if unique, false if taken.
  /// Throws on network/permission errors to prevent duplicate registrations.
  Future<bool> isUsernameUnique(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('name', isEqualTo: username)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      return query.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking username: $e');
      // SECURITY FIX: Do NOT return true on error — that would allow duplicate usernames.
      // Rethrow so the caller can show an appropriate error message.
      throw Exception(
        'Не удалось проверить имя пользователя. Проверьте интернет.',
      );
    }
  }

  Future<String?> register(String name, String email, String password) async {
    _isRegistering = true;
    try {
      if (_moderationService.hasProfanity(name)) {
        return 'Имя содержит недопустимые выражения.';
      }

      debugPrint('📝 AUTH: START Registration process');

      // 1. Create User in Firebase Auth
      final credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 25),
            onTimeout: () =>
                throw TimeoutException('Превышено время ожидания регистрации'),
          );

      if (credential.user == null) return 'Ошибка создания пользователя';
      final String uid = credential.user!.uid;
      debugPrint('📝 AUTH: Firebase User Created [uid: $uid]');

      // 2. Prepare Data Model
      final userModel = UserModel(
        uid: uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      // 3. Save to Firestore SYNCHRONOUSLY — critical for user data integrity
      try {
        await Future.wait([
          _firestore.collection('users').doc(uid).set(userModel.toMap()),
          credential.user!.updateDisplayName(name),
        ]).timeout(const Duration(seconds: 10));
        debugPrint('✅ AUTH: Profile data saved to Firestore');
      } catch (e) {
        debugPrint('⚠️ AUTH: Firestore write failed: $e');
        // Profile data didn't save — still let user in, data will sync later
      }

      // 4. Set local state — UI can navigate
      currentUser.value = userModel;
      isLoggedIn.value = true;
      debugPrint('✅ AUTH: Local state set, UI can navigate now');

      // 5. Save FCM Token (fire & forget — non-critical)
      () async {
        try {
          final token = await NotificationService().getToken().timeout(
            const Duration(seconds: 5),
          );
          if (token != null) NotificationService().saveTokenToFirestore(token);
        } catch (e) {
          debugPrint('⚠️ FCM token fetch failed: $e');
        }
      }();

      // Track stats: New User via Data
      _trackNewUser();

      debugPrint('✅ AUTH: Регистрация полностью завершена');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AUTH: Ошибка Firebase (${e.code})');
      return _getErrorMessage(e.code);
    } catch (e) {
      debugPrint('❌ AUTH: Критическая ошибка: $e');
      return 'Произошла ошибка. Попробуйте позже';
    } finally {
      // Keep _isRegistering = true briefly to prevent authStateChanges
      // from re-triggering _loadUserData (which causes duplicate Firestore reads)
      Future.delayed(const Duration(seconds: 2), () {
        _isRegistering = false;
      });
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? age,
    String? education,
    String? city,
    int? untScore,
    double? ieltsScore,
    double? gpa,
    int? mathScore,
    String? photoUrl,
    // 📋 Расширенный профиль (перенесено из StudentProfile)
    List<String>? preferredCities,
    int? budget,
    String? targetProfession,
    String? financialSituation,
    bool? hasDisability,
    bool? isOrphan,
    bool? isRural,
    bool? specialExamPassed,
    List<String>? extracurriculars,
    // 🎯 ЕНТ направление
    String? subjectType,
    String? entSubject1,
    String? entSubject2,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || currentUser.value == null) return false;

      final updatedUser = currentUser.value!.copyWith(
        name: name ?? currentUser.value!.name,
        age: age ?? currentUser.value!.age,
        education: education ?? currentUser.value!.education,
        city: city ?? currentUser.value!.city,
        untScore: untScore ?? currentUser.value!.untScore,
        ieltsScore: ieltsScore ?? currentUser.value!.ieltsScore,
        gpa: gpa ?? currentUser.value!.gpa,
        mathScore: mathScore ?? currentUser.value!.mathScore,
        photoUrl: photoUrl ?? currentUser.value!.photoUrl,
        updatedAt: DateTime.now(),
        // 📋 Расширенный профиль
        preferredCities: preferredCities ?? currentUser.value!.preferredCities,
        budget: budget ?? currentUser.value!.budget,
        targetProfession:
            targetProfession ?? currentUser.value!.targetProfession,
        financialSituation:
            financialSituation ?? currentUser.value!.financialSituation,
        hasDisability: hasDisability ?? currentUser.value!.hasDisability,
        isOrphan: isOrphan ?? currentUser.value!.isOrphan,
        isRural: isRural ?? currentUser.value!.isRural,
        specialExamPassed:
            specialExamPassed ?? currentUser.value!.specialExamPassed,
        extracurriculars:
            extracurriculars ?? currentUser.value!.extracurriculars,
        // 🎯 ЕНТ направление
        subjectType: subjectType ?? currentUser.value!.subjectType,
        entSubject1: entSubject1 ?? currentUser.value!.entSubject1,
        entSubject2: entSubject2 ?? currentUser.value!.entSubject2,
      );

      // Moderation check is now handled exclusively in the UI (edit_profile_screen.dart)
      // to provide localized error messages to the user.

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(updatedUser.toMap());

      if (name != null) {
        await user.updateDisplayName(name);
      }
      // ⭐ Update photoURL in Firebase Auth
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      currentUser.value = updatedUser;
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  // API key provided by user to fix Google Play profile upload issues
  static const String _imgbbApiKey = '16ea590b6156b5c9fbc737026770d231';

  /// Upload profile photo to ImgBB (Free storage)
  Future<String?> uploadProfilePhoto(File file) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Validate file size (max 5MB)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        debugPrint('❌ File too large: ${fileSize ~/ 1024}KB (max 5MB)');
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload'),
      );

      request.fields['key'] = _imgbbApiKey;
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);
        final String? downloadUrl = data['data']?['url'];
        return downloadUrl;
      } else {
        debugPrint('ImgBB Error status: ${response.statusCode}');
        return null;
      }
    } on TimeoutException {
      debugPrint('❌ ImgBB upload timeout');
      return null;
    } catch (e) {
      debugPrint('ImgBB upload error: $e');
      return null;
    }
  }

  /// Add university to favorites
  Future<bool> addToFavorites(String universityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null || currentUser.value == null) return false;

      final favorites = List<String>.from(
        currentUser.value!.favoriteUniversities,
      );
      if (!favorites.contains(universityId)) {
        favorites.add(universityId);

        await _firestore.collection('users').doc(user.uid).update({
          'favoriteUniversities': favorites,
        });

        currentUser.value = currentUser.value!.copyWith(
          favoriteUniversities: favorites,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Add to favorites error: $e');
      return false;
    }
  }

  /// Remove university from favorites
  Future<bool> removeFromFavorites(String universityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null || currentUser.value == null) return false;

      final favorites = List<String>.from(
        currentUser.value!.favoriteUniversities,
      );
      favorites.remove(universityId);

      await _firestore.collection('users').doc(user.uid).update({
        'favoriteUniversities': favorites,
      });

      currentUser.value = currentUser.value!.copyWith(
        favoriteUniversities: favorites,
      );
      return true;
    } catch (e) {
      debugPrint('Remove from favorites error: $e');
      return false;
    }
  }

  /// Check if university is in favorites
  bool isFavorite(String universityId) {
    return currentUser.value?.favoriteUniversities.contains(universityId) ??
        false;
  }

  /// Get favorite university IDs
  List<String> getFavoriteIds() {
    return currentUser.value?.favoriteUniversities ?? [];
  }

  /// Update user subscription plan (Free, Pro, Premium)
  Future<bool> updateSubscriptionPlan(String plan, int initialTokens) async {
    try {
      final user = _auth.currentUser;
      if (user == null || currentUser.value == null) return false;

      final now = DateTime.now().toUtc();

      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionPlan': plan,
        'aiTokensRemaining': initialTokens,
        'lastTokenResetDate': now,
      });

      // Update local state
      currentUser.value = currentUser.value!.copyWith(
        subscriptionPlan: plan,
        aiTokensRemaining: initialTokens,
        lastTokenResetDate: now,
      );

      return true;
    } catch (e) {
      debugPrint('Error updating subscription plan: $e');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      currentUser.value = null;
      isLoggedIn.value = false;
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Get error message from FirebaseAuthException
  String getErrorMessage(FirebaseAuthException e) {
    return _getErrorMessage(e.code);
  }

  /// Get error message from error code
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован. Попробуйте войти или используйте другой email';
      case 'weak-password':
        return 'Слишком слабый пароль. Минимум 6 символов';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'user-disabled':
        return 'Этот аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'network-request-failed':
        return 'Проблема с интернетом. Проверьте подключение';
      case 'invalid-credential':
        return 'Неверный email или пароль';
      case 'operation-not-allowed':
        return 'Регистрация временно недоступна';
      default:
        return 'Произошла ошибка: $code';
    }
  }

  /// Sign In Anonymously (Guest)
  Future<String?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      if (userCredential.user != null) {
        // Create a temporary guest user model locally if needed,
        // or just rely on isLoggedIn = true and currentUser = null/GuestModel
        // For now, we won't create a Firestore document for guests to keep DB clean,
        // or we can create one with a 'guest' role.
        // Let's create a local User object for UI consistency but NOT save to Firestore yet.

        currentUser.value = UserModel(
          uid: userCredential.user!.uid,
          name: 'Гость',
          email: 'guest@tandau.app', // Dummy email
          createdAt: DateTime.now(),
        );
        isLoggedIn.value = true;
        return null;
      }
      return 'Ошибка входа гостем';
    } on FirebaseAuthException catch (e) {
      debugPrint('Guest login Firebase error: ${e.code} - ${e.message}');
      if (e.code == 'operation-not-allowed') {
        return 'Вход гостем отключен в настройках Firebase. Обратитесь к администратору.';
      }
      return 'Ошибка входа: ${e.message}';
    } catch (e) {
      debugPrint('Guest login error: $e');
      return 'Не удалось войти как гость. Проверьте интернет.';
    }
  }

  /// Check if current user is guest
  bool get isGuest {
    return _auth.currentUser?.isAnonymous ?? false;
  }

  /// Check if current user is admin.
  /// Checks both the Firestore 'role' field and a hardcoded email list synced with firestore.rules.
  bool get isAdmin {
    final email = currentUser.value?.email.toLowerCase();
    final isHardcodedAdmin =
        email != null &&
        [
          'admin@tandau.app',
          'tandau.admin@gmail.com',
          'lolpro2312nn@gmail.com',
          'robloxlolpro2312@gmail.com',
        ].contains(email);
    return isHardcodedAdmin || currentUser.value?.role == 'admin';
  }

  /// Check if current user is moderator
  bool get isModerator {
    return currentUser.value?.role == 'moderator';
  }

  /// Check if user has admin panel access (Admin or Moderator)
  bool get hasAdminAccess {
    return isAdmin || isModerator;
  }

  /// Update admin/moderator session details (IP, Device, Last Online)
  Future<void> _updateSessionInfo(UserModel user) async {
    try {
      String ip = 'unknown';
      try {
        final response = await http
            .get(Uri.parse('https://api.ipify.org?format=json'))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          ip = data['ip'] ?? 'unknown';
        }
      } catch (e) {
        debugPrint('Failed to get IP: $e');
      }

      String device;
      try {
         if (kIsWeb) {
           device = 'Web (${defaultTargetPlatform.name})';
         } else {
           device = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
         }
      } catch (_) {
         device = 'Unknown';
      }

      final updates = {
        'lastOnline': FieldValue.serverTimestamp(),
        'lastIp': ip,
        'lastDevice': device,
      };

      await _firestore.collection('users').doc(user.uid).update(updates);

      // Update local state selectively
      if (currentUser.value?.uid == user.uid) {
        currentUser.value = currentUser.value!.copyWith(
          lastIp: ip,
          lastDevice: device,
          lastOnline: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Failed to update session info: $e');
    }
  }

  /// Track new user on backend
  Future<void> _trackNewUser() async {
    try {
      final uri = Uri.parse(
        'https://tandau-backend.onrender.com/v1/stats/user-created',
      );
      // Fire and forget with 10s timeout to prevent lingering HTTP handles
      http
          .post(uri)
          .timeout(const Duration(seconds: 10))
          .then((response) {
            if (response.statusCode != 200) {
              debugPrint('⚠️ Stats API error: ${response.body}');
            }
          })
          .catchError((e) {
            debugPrint('⚠️ Error tracking user: $e');
          });
    } catch (e) {
      debugPrint('⚠️ Error initiating user tracking: $e');
    }
  }
}
