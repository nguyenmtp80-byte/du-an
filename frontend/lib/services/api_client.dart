import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint').replace(
      queryParameters: queryParameters,
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: _headers(token, extraHeaders: extraHeaders),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(_connectionErrorMessage(error));
    }
  }

  Future<List<Map<String, dynamic>>> getList(
    String endpoint, {
    String? token,
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint').replace(
      queryParameters: queryParameters,
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: _headers(token, extraHeaders: extraHeaders),
          )
          .timeout(const Duration(seconds: 15));

      return _handleListResponse(response);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(_connectionErrorMessage(error));
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await _client
          .post(
            uri,
            headers: _headers(token, extraHeaders: extraHeaders),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(_connectionErrorMessage(error));
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await _client
          .put(
            uri,
            headers: _headers(token, extraHeaders: extraHeaders),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(_connectionErrorMessage(error));
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await _client
          .delete(
            uri,
            headers: _headers(token, extraHeaders: extraHeaders),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(_connectionErrorMessage(error));
    }
  }

  String _connectionErrorMessage(Object error) {
    final base =
        'Không thể kết nối API tại ${ApiConfig.baseUrl}.\n'
        'Kiểm tra backend đang chạy: .\\mvnw.cmd spring-boot:run';

    if (kIsWeb) {
      return '$base\n\n'
          'Flutter Web bị trình duyệt chặn CORS.\n'
          '${ApiConfig.webConnectionHint}';
    }

    return '$base\n\nChi tiết: $error';
  }

  Map<String, String> _headers(
    String? token, {
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  List<Map<String, dynamic>> _handleListResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    if (response.body.isEmpty) {
      if (isSuccess) {
        return [];
      }

      throw ApiException(
        'Yêu cầu thất bại (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      if (!isSuccess) {
        throw ApiException(
          'Yêu cầu thất bại (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      if (isSuccess) {
        final data = decoded['data'] ?? decoded['content'] ?? decoded['items'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      final message = decoded['message'] as String? ??
          decoded['error'] as String? ??
          'Yêu cầu thất bại (${response.statusCode})';

      throw ApiException(message, statusCode: response.statusCode);
    }

    throw ApiException(
      'Phản hồi không hợp lệ từ server (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    if (response.body.isEmpty) {
      if (isSuccess) {
        return {};
      }

      throw ApiException(
        'Yêu cầu thất bại (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      if (isSuccess) {
        return {};
      }

      throw ApiException(
        'Phản hồi không hợp lệ từ server (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (isSuccess) {
      return decoded;
    }

    final message = decoded['message'] as String? ??
        decoded['error'] as String? ??
        'Yêu cầu thất bại (${response.statusCode})';

    throw ApiException(message, statusCode: response.statusCode);
  }
}
