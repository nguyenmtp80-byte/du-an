import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/auth_response.dart';
import '../models/user.dart';
import '../services/auth_api_service.dart';

/// Repository auth: gọi API Spring Boot và lưu session cục bộ.
class AuthRepository {
  AuthRepository({
    AuthApiService? authApiService,
    SharedPreferences? prefs,
    Uuid? uuid,
  })  : _authApiService = authApiService ?? AuthApiService(),
        _prefs = prefs,
        _uuid = uuid ?? const Uuid();

  final AuthApiService _authApiService;
  final Uuid _uuid;
  SharedPreferences? _prefs;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    final loginId = await _resolveLoginId(trimmedEmail);

    final response = await _authApiService.login(
      id: loginId,
      email: trimmedEmail,
      password: password,
    );

    await _saveSession(response);
    return response;
  }

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? studentId,
  }) async {
    final response = await _authApiService.register(
      id: _uuid.v4(),
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      fullName: fullName,
      phone: phone,
      studentId: studentId,
    );

    await _saveSession(response);
    return response;
  }

  Future<void> logout() async {
    final prefs = await _preferences;
    final token = prefs.getString(_tokenKey);

    if (token != null && token.isNotEmpty) {
      try {
        await _authApiService.logout(token: token);
      } catch (_) {
        // Vẫn xóa session local nếu server không phản hồi.
      }
    }

    await _clearSession();
  }

  Future<User?> getStoredUser() async {
    final prefs = await _preferences;
    final userJson = prefs.getString(_userKey);

    if (userJson == null) {
      return null;
    }

    return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  Future<String?> getStoredToken() async {
    final prefs = await _preferences;
    return prefs.getString(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }

  Future<String> _resolveLoginId(String email) async {
    final storedUser = await getStoredUser();

    if (storedUser != null &&
        storedUser.email.toLowerCase() == email.toLowerCase()) {
      return storedUser.id;
    }

    // Backend ưu tiên tìm theo id, nếu không có sẽ fallback sang email.
    return email;
  }

  Future<void> _saveSession(AuthResponse response) async {
    final prefs = await _preferences;
    await prefs.setString(_tokenKey, response.token);
    await prefs.setString(_userKey, jsonEncode(response.user.toJson()));
  }

  Future<void> _clearSession() async {
    final prefs = await _preferences;
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
