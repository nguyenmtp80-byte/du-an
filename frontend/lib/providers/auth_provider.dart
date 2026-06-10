import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';

enum AuthStatus {
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  bool _isInitializing = true;
  bool _isSubmitting = false;
  AuthStatus _status = AuthStatus.unauthenticated;
  User? _user;
  String? _errorMessage;

  bool get isInitializing => _isInitializing;
  bool get isLoading => _isSubmitting;
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    final isLoggedIn = await _authRepository.isLoggedIn();
    if (isLoggedIn) {
      _user = await _authRepository.getStoredUser();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> login({required String email}) async {
    _beginSubmit();

    try {
      final response = await _authRepository.login(email: email);
      _user = response.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _endSubmit();
      return true;
    } on ApiException catch (error) {
      _handleSubmitError(error.message);
      return false;
    } catch (_) {
      _handleSubmitError('Đã xảy ra lỗi không xác định. Vui lòng thử lại.');
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    String? studentId,
  }) async {
    _beginSubmit();

    try {
      final response = await _authRepository.register(
        fullName: fullName,
        email: email,
        phone: phone,
        studentId: studentId,
      );
      _user = response.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _endSubmit();
      return true;
    } on ApiException catch (error) {
      _handleSubmitError(error.message);
      return false;
    } catch (_) {
      _handleSubmitError('Đã xảy ra lỗi không xác định. Vui lòng thử lại.');
      return false;
    }
  }

  Future<void> logout() async {
    _beginSubmit();

    await _authRepository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _endSubmit();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _beginSubmit() {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _endSubmit() {
    _isSubmitting = false;
    notifyListeners();
  }

  void _handleSubmitError(String message) {
    _isSubmitting = false;
    _errorMessage = message;
    notifyListeners();
  }
}
