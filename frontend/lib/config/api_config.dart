import 'package:flutter/foundation.dart';

/// Cấu hình URL backend Spring Boot (`market-place-app`).
class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080/api';
      default:
        return 'http://localhost:8080/api';
    }
  }

  /// Gợi ý khi Flutter Web không gọi được API (CORS trình duyệt).
  static String get webConnectionHint =>
      'Chạy trên Windows: flutter run -d windows\n'
      'Hoặc Chrome dev: flutter run -d chrome '
      '--web-browser-flag=--disable-web-security '
      '--web-browser-flag=--user-data-dir=C:/temp/flutter_chrome_dev';

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
}
