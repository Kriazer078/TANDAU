import 'package:flutter/material.dart';
import 'dart:async'; // Import async for TimeoutException
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign In
import 'package:shared_preferences/shared_preferences.dart'; // Import for persistent attempts
import 'dart:io'; // ⭐ Import File
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn =
      GoogleSignIn(); // Initialize Google Sign In

  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  final ValueNotifier<UserModel?> currentUser = ValueNotifier<UserModel?>(null);

  // Constants for login limiting
  static const String _attemptsKey = 'login_attempts';
  static const String _lockoutTimeKey = 'lockout_time';
  static const int _maxAttempts = 5;
  static const int _lockoutDurationMinutes = 5;

  /// Initialize and check auth state
  Future<void> init() async {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        isLoggedIn.value = true;
        // Load user data in background
        _loadUserData(user.uid);
      } else {
        isLoggedIn.value = false;
        currentUser.value = null;
      }
    });

    // Check if user is already logged in
    final user = _auth.currentUser;
    if (user != null) {
      isLoggedIn.value = true;
      // Load user data in background to prevent app freeze
      _loadUserData(user.uid);
    }
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        currentUser.value = UserModel.fromDocument(doc);
      }
    } catch (e) {
      debugPrint(
        'Error loading user data (might be offline or permission denied): $e',
      );
    }
  }

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

        // Load user data in background
        _loadUserData(credential.user!.uid);
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
      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('🚫 Google Sign-In canceled by user');
        return 'Вход отменен'; // User canceled the sign-in
      }

      debugPrint('✅ Google User obtained: ${googleUser.email}');

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint('✅ Google Auth details obtained');

      // 3. Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
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
              name: user.displayName ?? googleUser.displayName ?? 'Google User',
              email: user.email ?? googleUser.email,
              createdAt: DateTime.now(),
            );
            await _firestore
                .collection('users')
                .doc(user.uid)
                .set(userModel.toMap());
          }
        } catch (e) {
          debugPrint(
            'Error checking user/creating user in Firestore (continuing): $e',
          );
        }

        // Load user data in background
        _loadUserData(user.uid);
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
      // If permission denied (rules block reading users) or timeout, assume unique to allow registration
      return true;
    }
  }

  /// Register new user
  /// Returns null on success, error message on failure
  Future<String?> register(String name, String email, String password) async {
    try {
      debugPrint('📝 Starting registration for: $email');

      // Create user in Firebase Auth
      final credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Превышено время ожидания');
            },
          );

      if (credential.user != null) {
        debugPrint('✅ Firebase Auth user created: ${credential.user!.uid}');

        // Create user document in Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );

        final firestoreTask = _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toMap())
            .catchError((e) {
              debugPrint('⚠️ Firestore error (non-critical): $e');
            });

        final displayNameTask = credential.user!
            .updateDisplayName(name)
            .catchError((e) {
              debugPrint('⚠️ Display name error (non-critical): $e');
            });

        // Run tasks in parallel, but don't block forever
        try {
          await Future.wait([
            firestoreTask,
            displayNameTask,
          ]).timeout(const Duration(seconds: 5));
          debugPrint('✅ Firestore and Display Name tasks completed');
        } catch (e) {
          debugPrint('⚠️ Profile setup timed out or failed (continuing): $e');
        }

        currentUser.value = userModel;
        isLoggedIn.value = true;
        debugPrint('✅ Registration process finished');
        return null; // Success
      }
      return 'Ошибка регистрации';
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Registration error: ${e.code} - ${e.message}');
      return _getErrorMessage(e.code);
    } on TimeoutException {
      return 'Превышено время ожидания. Проверьте интернет.';
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      return 'Произошла ошибка. Попробуйте позже';
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
    double? gpa, // ⭐ Added GPA
    int? mathScore, // ⭐ Added Math Score
    String? photoUrl,
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
        gpa: gpa ?? currentUser.value!.gpa, // ⭐
        mathScore: mathScore ?? currentUser.value!.mathScore, // ⭐
        photoUrl: photoUrl ?? currentUser.value!.photoUrl,
        updatedAt: DateTime.now(),
      );

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

  /// Upload profile photo to ImgBB (Free storage)
  Future<String?> uploadProfilePhoto(File file) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload'),
      );

      request.fields['key'] = '16ea590b6156b5c9fbc737026770d231';
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);
        final String? downloadUrl = data['data']['url'];
        return downloadUrl;
      } else {
        debugPrint('ImgBB Error status: ${response.statusCode}');
        return null;
      }
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
}
