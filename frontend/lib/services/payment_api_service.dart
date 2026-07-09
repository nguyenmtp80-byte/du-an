import '../config/api_config.dart';
import '../models/payment_qr.dart';
import 'api_client.dart';

class PaymentApiService {
  PaymentApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PaymentInfo> getPaymentInfo({
    required String userId,
    required String orderId,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.paymentInfoEndpoint(orderId),
      extraHeaders: {'X-User-Id': userId},
    );

    return PaymentInfo.fromJson(response);
  }

  Future<PaymentQr> getPaymentQr({
    required String userId,
    required String orderId,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.paymentQrEndpoint(orderId),
      extraHeaders: {'X-User-Id': userId},
    );

    return PaymentQr.fromJson(response);
  }

  Future<Map<String, dynamic>> confirmQrPayment({
    required String userId,
    required String orderId,
  }) {
    return _apiClient.post(
      ApiConfig.paymentConfirmTransferEndpoint(orderId),
      extraHeaders: {'X-User-Id': userId},
    );
  }

  Future<Map<String, dynamic>> confirmSellerReceived({
    required String userId,
    required String orderId,
  }) {
    return _apiClient.put(
      ApiConfig.paymentSellerConfirmEndpoint(orderId),
      extraHeaders: {'X-User-Id': userId},
    );
  }

  Future<Map<String, dynamic>> cancelQrPayment({
    required String userId,
    required String orderId,
  }) {
    return _apiClient.put(
      ApiConfig.paymentQrCancelEndpoint(orderId),
      extraHeaders: {'X-User-Id': userId},
    );
  }

  /// Kiểm tra trạng thái giao dịch — dùng cho polling
  /// Trả về map có field "status": "PENDING" | "SUCCESS" | "FAILED"
  Future<Map<String, dynamic>> checkTransaction({
    required String userId,
    required String orderId,
  }) {
    return _apiClient.get(
      ApiConfig.paymentTransactionEndpoint(orderId),
      extraHeaders: {'X-User-Id': userId},
    );
  }
}
