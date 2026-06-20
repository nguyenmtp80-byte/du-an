import '../config/api_config.dart';
import '../models/order.dart';
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

  Future<List<Order>> getUserOrders({required String userId}) async {
    final response = await _apiClient.getList(
      ApiConfig.ordersEndpoint,
      extraHeaders: {'X-User-Id': userId},
    );

    return response.map(Order.fromJson).toList();
  }

  Future<Order> getOrderDetail({
    required String userId,
    required String orderId,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.orderDetailEndpoint(orderId),
      extraHeaders: {'X-User-Id': userId},
    );

    return Order.fromJson(response);
  }
}
