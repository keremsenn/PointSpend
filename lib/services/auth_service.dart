import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final UserService _userService;

  AuthService({FirebaseAuth? auth, UserService? userService})
      : _auth = auth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService();

  static const String _keyUserId = 'user_id_session';
  static const String _keySessionDate = 'session_login_timestamp';
  static const int _sessionValidityDays = 30;

  User? get currentUser => _auth.currentUser;

  /// Check if a valid local session exists (within 30 days)
  Future<String?> getValidSessionUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(_keyUserId);
      final savedTimestamp = prefs.getInt(_keySessionDate);

      if (savedUserId != null && savedTimestamp != null) {
        final sessionDate = DateTime.fromMillisecondsSinceEpoch(savedTimestamp);
        final difference = DateTime.now().difference(sessionDate).inDays;

        if (difference < _sessionValidityDays) {
          return savedUserId;
        }
      }
    } catch (e) {
      if (kDebugMode) print('SharedPreferences session error: $e');
    }
    return null;
  }

  /// Save session locally for 30 days
  Future<void> saveSession(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
      await prefs.setInt(_keySessionDate, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) print('Save session error: $e');
    }
  }

  /// Update Name, Email and/or Password in Firebase Auth and Firestore
  Future<void> updateUserCredentials({
    required String userId,
    String? newName,
    String? newEmail,
    String? newPassword,
  }) async {
    final user = _auth.currentUser;
    final Map<String, dynamic> updates = {};

    if (newName != null && newName.trim().isNotEmpty) {
      if (user != null) {
        await user.updateDisplayName(newName.trim());
      }
      updates['name'] = newName.trim();
    }

    if (newEmail != null && newEmail.trim().isNotEmpty) {
      if (user != null && user.email != newEmail.trim()) {
        await user.verifyBeforeUpdateEmail(newEmail.trim());
      }
      updates['email'] = newEmail.trim();
    }

    if (newPassword != null && newPassword.trim().isNotEmpty) {
      if (user != null) {
        try {
          await user.updatePassword(newPassword.trim());
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            throw Exception('Güvenlik nedeniyle şifre değiştirmek için lütfen çıkış yapıp tekrar giriş yapınız.');
          } else if (e.code == 'weak-password') {
            throw Exception('Şifreniz çok zayıf. En az 6 karakter olmalıdır.');
          } else {
            throw Exception(e.message ?? 'Şifre güncellenemedi.');
          }
        }
      } else {
        throw Exception('Aktif Firebase oturumu bulunamadı. Lütfen tekrar giriş yapınız.');
      }
    }

    if (updates.isNotEmpty) {
      await _userService.updateUser(userId, updates);
    }
  }

  /// Logout and clear saved session
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keySessionDate);
    } catch (_) {}
  }

  /// Login with Email & Password (Strict Authentication Verification)
  Future<UserProfile> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Kullanıcı doğrulanamadı.');
      }

      var profile = await _userService.getUser(user.uid);
      if (profile == null) {
        profile = UserProfile(
          id: user.uid,
          name: user.displayName ?? email.split('@').first,
          email: email.trim(),
          totalPoints: 1250,
          proStatus: false,
          tier: 'Free',
          profileStatus: 'active',
          createdAt: DateTime.now(),
        );
        await _userService.createUser(profile);
      }

      await saveSession(profile.id);
      return profile;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw Exception('E-posta adresi veya şifre hatalı!');
      } else if (e.code == 'wrong-password') {
        throw Exception('Girdiğiniz şifre hatalı!');
      } else if (e.code == 'invalid-email') {
        throw Exception('Geçersiz bir e-posta adresi girdiniz.');
      } else if (e.code == 'user-disabled') {
        throw Exception('Bu kullanıcı hesabı askıya alınmış.');
      } else {
        throw Exception(e.message ?? 'Giriş yapılamadı. Şifrenizi kontrol ediniz.');
      }
    } catch (e) {
      throw Exception('Giriş yapılırken hata oluştu: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  /// Register new user with Email & Password (Default proStatus = false)
  Future<UserProfile> registerWithEmail(String name, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Kullanıcı kaydı oluşturulamadı.');
      }

      await user.updateDisplayName(name.trim());

      final newProfile = UserProfile(
        id: user.uid,
        name: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
        email: email.trim(),
        totalPoints: 1250,
        proStatus: false,
        tier: 'Free',
        profileStatus: 'active',
        createdAt: DateTime.now(),
      );

      await _userService.createUser(newProfile);
      await saveSession(newProfile.id);
      return newProfile;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          final loginResult = await _auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          final user = loginResult.user;
          if (user != null) {
            var profile = await _userService.getUser(user.uid);
            if (profile == null) {
              profile = UserProfile(
                id: user.uid,
                name: name.trim().isNotEmpty ? name.trim() : email.split('@').first,
                email: email.trim(),
                totalPoints: 1250,
                proStatus: false,
                tier: 'Free',
                profileStatus: 'active',
                createdAt: DateTime.now(),
              );
              await _userService.createUser(profile);
            }
            await saveSession(profile.id);
            return profile;
          }
        } catch (_) {
          throw Exception('Bu e-posta adresi zaten kayıtlı! Lütfen "Giriş Yap" sekmesini kullanarak şifrenizle giriş yapın.');
        }
      } else if (e.code == 'weak-password') {
        throw Exception('Şifreniz çok zayıf. Lütfen en az 6 karakterli bir şifre belirleyin.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Geçersiz bir e-posta adresi girdiniz.');
      } else {
        throw Exception(e.message ?? 'Kayıt olunamadı.');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }

    throw Exception('Kayıt oluşturulamadı.');
  }

  /// Quick 1-click Guest Login
  Future<UserProfile> guestLogin() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;
      if (user != null) {
        final newProfile = UserProfile(
          id: user.uid,
          name: 'Misafir Kullanıcı',
          email: 'misafir@pointspend.app',
          totalPoints: 1250,
          proStatus: false,
          tier: 'Free',
          profileStatus: 'active',
          createdAt: DateTime.now(),
        );
        await _userService.createUser(newProfile);
        await saveSession(newProfile.id);
        return newProfile;
      }
    } catch (e) {
      if (kDebugMode) print('Guest login error: $e');
    }

    const fallbackId = 'demo_user_guest';
    final demoProfile = UserProfile(
      id: fallbackId,
      name: 'Misafir Kullanıcı',
      email: 'misafir@pointspend.app',
      totalPoints: 1250,
      proStatus: false,
      tier: 'Free',
      profileStatus: 'active',
      createdAt: DateTime.now(),
    );

    try {
      await _userService.createUser(demoProfile);
    } catch (_) {}

    await saveSession(fallbackId);
    return demoProfile;
  }
}
