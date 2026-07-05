import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.0.2.2',
  );

  static String get _apiOrigin => 'http://$_host:8080';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '$_apiOrigin/api';
      default:
        return 'http://localhost:8080/api';
    }
  }

  static String get webConnectionHint =>
      'Chạy trên Windows: flutter run -d windows\n'
      'Hoặc Chrome dev: flutter run -d chrome '
      '--web-browser-flag=--disable-web-security '
      '--web-browser-flag=--user-data-dir=C:/temp/flutter_chrome_dev';

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';

  static const String productsEndpoint = '/products';
  static const String uploadImagesEndpoint = '/upload/images';
  static String get baseUploadUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _apiOrigin;
      default:
        return 'http://localhost:8080';
    }
  }

  static String productDetailEndpoint(String productId) => '/products/$productId';
  static const String cartAddEndpoint = '/cart/add';
  static const String cartEndpoint = '/cart';
  static const String cartUpdateEndpoint = '/cart/update';
  static String cartDeleteEndpoint(String cartItemId) => '/cart/$cartItemId';
  static const String orderCreateEndpoint = '/orders/create';
  static const String ordersEndpoint = '/orders';
  static const String sellerOrdersEndpoint = '/orders/seller/list';
  static String orderDetailEndpoint(String orderId) => '/orders/$orderId';
  static String paymentInfoEndpoint(String orderId) => '/payments/$orderId/info';
  static String paymentQrEndpoint(String orderId) => '/payments/$orderId/qr';
  static String paymentQrConfirmEndpoint(String orderId) =>
      '/payments/$orderId/qr/confirm';
  static String paymentQrCancelEndpoint(String orderId) =>
      '/payments/$orderId/qr/cancel';
  static String orderAcceptEndpoint(String orderId) => '/orders/$orderId/accept';
  static String orderCancelEndpoint(String orderId) => '/orders/$orderId/cancel';
  static String orderCompleteEndpoint(String orderId) => '/orders/$orderId/complete';

  static const String chatRoomsEndpoint = '/chat/rooms';
  static String chatRoomMessagesEndpoint(String roomId) => '/chat/rooms/$roomId/messages';
  static String chatRoomReadEndpoint(String roomId) => '/chat/rooms/$roomId/read';

  static const String notificationsEndpoint = '/notifications';
  static const String notificationsUnreadCountEndpoint = '/notifications/unread/count';
  static const String notificationsReadAllEndpoint = '/notifications/read-all';
  static String notificationReadEndpoint(String notificationId) =>
      '/notifications/$notificationId/read';

  static const List<String> devProductIds = ['prod-1', 'prod-2', 'prod-3'];
}
