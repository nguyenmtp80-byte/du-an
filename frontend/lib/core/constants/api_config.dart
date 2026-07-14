class ApiConfig {
  ApiConfig._();

  static const String _productionOrigin =
      'https://marketplace-production-5909.up.railway.app';

  static String get baseUrl => '$_productionOrigin/api';
  static String get baseUploadUrl => _productionOrigin;

  static String get webConnectionHint =>
      'Chạy trên Windows: flutter run -d windows\n'
      'Hoặc Chrome dev: flutter run -d chrome '
      '--web-browser-flag=--disable-web-security '
      '--web-browser-flag=--user-data-dir=C:/temp/flutter_chrome_dev';

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String googleLoginEndpoint = '/auth/google';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String logoutEndpoint = '/auth/logout';
  static const String sendRegisterOtpEndpoint = '/auth/send-register-otp';
  static const String verifyRegisterOtpEndpoint = '/auth/verify-register-otp';

  static const String productsEndpoint = '/products';
  static const String uploadImagesEndpoint = '/upload/images';
  static String productDetailEndpoint(String productId) => '/products/$productId';

  static const String cartAddEndpoint = '/cart/add';
  static const String cartEndpoint = '/cart';
  static const String cartUpdateEndpoint = '/cart/update';
  static String cartDeleteEndpoint(String cartItemId) => '/cart/$cartItemId';

  static const String orderCreateEndpoint = '/orders/create';
  static const String ordersEndpoint = '/orders';
  static const String sellerOrdersEndpoint = '/orders/seller/list';
  static String orderDetailEndpoint(String orderId) => '/orders/$orderId';
  static String orderAcceptEndpoint(String orderId) => '/orders/$orderId/accept';
  static String orderCancelEndpoint(String orderId) => '/orders/$orderId/cancel';
  static String orderCompleteEndpoint(String orderId) => '/orders/$orderId/complete';

  static String paymentInfoEndpoint(String orderId) => '/payments/$orderId/info';
  static String paymentQrEndpoint(String orderId) => '/payments/$orderId/qr';
  static String paymentConfirmTransferEndpoint(String orderId) =>
      '/payments/$orderId/confirm-transfer';
  static String paymentSellerConfirmEndpoint(String orderId) =>
      '/payments/$orderId/seller-confirm';
  static String paymentTransactionEndpoint(String orderId) =>
      '/payments/$orderId/transaction';
  static String paymentQrCancelEndpoint(String orderId) =>
      '/payments/$orderId/qr/cancel';

  static const String chatRoomsEndpoint = '/chat/rooms';
  static String chatRoomMessagesEndpoint(String roomId) =>
      '/chat/rooms/$roomId/messages';
  static String chatRoomReadEndpoint(String roomId) => '/chat/rooms/$roomId/read';

  static const String notificationsEndpoint = '/notifications';
  static const String notificationsUnreadCountEndpoint =
      '/notifications/unread/count';
  static const String notificationsReadAllEndpoint = '/notifications/read-all';
  static String notificationReadEndpoint(String notificationId) =>
      '/notifications/$notificationId/read';

  static const List<String> devProductIds = ['prod-1', 'prod-2', 'prod-3'];
}
