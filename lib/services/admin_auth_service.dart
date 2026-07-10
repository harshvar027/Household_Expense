import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feedback_config.dart';

class AdminAuthService {
  AdminAuthService._();

  static final AdminAuthService instance = AdminAuthService._();

  static const _passwordHashKey = 'admin_password_hash_v1';
  static const _usernameKey = 'admin_username_v1';

  final _secure = const FlutterSecureStorage();

  Future<bool> isAdminConfigured() async {
    final hash = await _secure.read(key: _passwordHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(FeedbackConfig.adminSessionKey) ?? false;
  }

  Future<String> getAdminUsername() async {
    final stored = await _secure.read(key: _usernameKey);
    return stored ?? FeedbackConfig.adminUsername;
  }

  Future<bool> setupAdmin({
    required String setupCode,
    required String username,
    required String password,
  }) async {
    if (setupCode.trim() != FeedbackConfig.adminSetupCode) return false;
    if (password.length < 6) return false;

    await _secure.write(key: _usernameKey, value: username.trim());
    await _secure.write(key: _passwordHashKey, value: _hashPassword(password));
    return true;
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (!await isAdminConfigured()) return false;

    final storedUser = await getAdminUsername();
    if (username.trim().toLowerCase() != storedUser.toLowerCase()) return false;

    final hash = await _secure.read(key: _passwordHashKey);
    if (hash == null || hash != _hashPassword(password)) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(FeedbackConfig.adminSessionKey, true);
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(FeedbackConfig.adminSessionKey, false);
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) return false;
    final hash = await _secure.read(key: _passwordHashKey);
    if (hash == null || hash != _hashPassword(currentPassword)) return false;
    await _secure.write(key: _passwordHashKey, value: _hashPassword(newPassword));
    return true;
  }

  String _hashPassword(String password) =>
      base64Url.encode(utf8.encode('household_admin_$password'));
}
