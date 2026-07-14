import '../core/constants/api_config.dart';
import '../models/auth_response.dart';
import 'api_client.dart';

class AuthApiService {
  AuthApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthResponse> login({
    required String id,
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.post(
      ApiConfig.loginEndpoint,
      body: {'id': id, 'email': email.trim(), 'password': password},
    );

    return AuthResponse.fromJson(data);
  }

  Future<AuthResponse> register({
    required String id,
    required String email,
    required String password,
    required String confirmPassword,
    String? fullName,
    String? phone,
    String? studentId,
    String? avatarUrl,
  }) async {
    final data = await _apiClient.post(
      ApiConfig.registerEndpoint,
      body: {
        'id': id,
        'email': email.trim(),
        'password': password,
        'confirmPassword': confirmPassword,
        if (fullName != null && fullName.trim().isNotEmpty)
          'fullName': fullName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (studentId != null && studentId.trim().isNotEmpty)
          'studentId': studentId.trim(),
        if (avatarUrl != null && avatarUrl.trim().isNotEmpty)
          'avatarUrl': avatarUrl.trim(),
      },
    );

    return AuthResponse.fromJson(data);
  }

  Future<void> logout({required String token}) async {
    await _apiClient.post(ApiConfig.logoutEndpoint, token: token);
  }

  Future<AuthResponse> googleLogin({required String idToken}) async {
    final data = await _apiClient.post(
      ApiConfig.googleLoginEndpoint,
      body: {'idToken': idToken},
    );

    return AuthResponse.fromJson(data);
  }

  Future<String> sendRegisterOtp({required String email}) async {
    final data = await _apiClient.post(
      ApiConfig.sendRegisterOtpEndpoint,
      body: {'email': email.trim()},
    );

    return data['message'] as String? ?? 'Mã OTP đã được gửi đến email của bạn';
  }

  Future<String> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    final data = await _apiClient.post(
      ApiConfig.verifyRegisterOtpEndpoint,
      body: {'email': email.trim(), 'otp': otp.trim()},
    );

    return data['message'] as String? ?? 'Xác thực email thành công';
  }

  Future<String> forgotPassword({required String email}) async {
    final data = await _apiClient.post(
      ApiConfig.forgotPasswordEndpoint,
      body: {'email': email.trim()},
    );

    return data['message'] as String? ?? 'OTP đã được gửi đến email của bạn';
  }

  Future<AuthResponse> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final data = await _apiClient.post(
      ApiConfig.resetPasswordEndpoint,
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    final authData = data['data'];
    if (authData is Map<String, dynamic>) {
      return AuthResponse.fromJson(authData);
    }

    return AuthResponse.fromJson(data);
  }
}
