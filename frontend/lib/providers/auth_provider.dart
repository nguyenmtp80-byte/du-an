import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';
import '../services/google_auth_service.dart';

enum AuthStatus {
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthRepository? authRepository,
    GoogleAuthService? googleAuthService,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _googleAuthService = googleAuthService ?? GoogleAuthService();

  final AuthRepository _authRepository;
  final GoogleAuthService _googleAuthService;

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

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _beginSubmit();

    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
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

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? studentId,
  }) async {
    _beginSubmit();

    try {
      final response = await _authRepository.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
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

    await _googleAuthService.signOut();
    await _authRepository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _endSubmit();
  }

  Future<bool> googleLogin({required String idToken}) async {
    _beginSubmit();

    try {
      if (idToken.isEmpty) {
        _handleSubmitError('Token Google không hợp lệ.');
        return false;
      }

      final response = await _authRepository.googleLogin(idToken: idToken);
      _user = response.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _endSubmit();
      return true;
    } on ApiException catch (error) {
      _handleSubmitError(error.message);
      return false;
    } catch (_) {
      _handleSubmitError('Không thể đăng nhập Google. Vui lòng thử lại.');
      return false;
    }
  }

  Future<String?> sendRegisterOtp({required String email}) async {
    _beginSubmit();

    try {
      final message = await _authRepository.sendRegisterOtp(email: email);
      _errorMessage = null;
      _endSubmit();
      return message;
    } on ApiException catch (error) {
      _handleSubmitError(error.message);
      return null;
    } catch (_) {
      _handleSubmitError('Không thể gửi OTP. Vui lòng thử lại.');
      return null;
    }
  }

  Future<String?> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    _beginSubmit();

    try {
      final message = await _authRepository.verifyRegisterOtp(
        email: email,
        otp: otp,
      );
      _errorMessage = null;
      _endSubmit();
      return message;
    } on ApiException catch (error) {
      _handleSubmitError(error.message);
      return null;
    } catch (_) {
      _handleSubmitError('Xác thực OTP thất bại. Vui lòng thử lại.');
      return null;
    }
  }

  Future<String?> requestPasswordReset({required String email}) async {
    _beginSubmit();

    try {
      final message = await _authRepository.forgotPassword(email: email);
      _errorMessage = null;
      _endSubmit();
      return message;
    } on ApiException catch (error) {
      _handleSubmitError(error.message);
      return null;
    } catch (_) {
      _handleSubmitError('Không thể gửi OTP. Vui lòng thử lại.');
      return null;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _beginSubmit();

    try {
      final response = await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
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
      _handleSubmitError('Không thể đặt lại mật khẩu. Vui lòng thử lại.');
      return false;
    }
  }

  GoogleAuthService get googleAuthService => _googleAuthService;

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