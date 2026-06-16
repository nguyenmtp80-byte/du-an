import '../config/api_config.dart';
import 'api_client.dart';

class OrderApiService {
  OrderApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> createOrder({
    required String userId,
    required String paymentMethod,
    required Map<String, dynamic> deliveryInfo,
  }) {
    return _apiClient.post(
      ApiConfig.orderCreateEndpoint,
      extraHeaders: {'X-User-Id': userId},
      body: {
        'paymentMethod': paymentMethod,
        'deliveryInfo': deliveryInfo,
      },
    );
  }
}
