import '../config/api_config.dart';
import '../models/auth_response.dart';
import 'api_client.dart';

class AuthApiService {
  AuthApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthResponse> login({
    required String id,
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.post(
      ApiConfig.loginEndpoint,
      body: {
        'id': id,
        'email': email.trim(),
        'password': password,
      },
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
    await _apiClient.post(
      ApiConfig.logoutEndpoint,
      token: token,
    );
  }
}
