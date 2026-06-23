import '../config/api_config.dart';
import '../models/order.dart';
import 'api_client.dart';

class OrderApiService {
  OrderApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Order> createOrder({
    required String userId,
    required String paymentMethod,
    required Map<String, dynamic> deliveryInfo,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.orderCreateEndpoint,
      extraHeaders: {'X-User-Id': userId},
      body: {
        'paymentMethod': paymentMethod,
        'deliveryInfo': deliveryInfo,
      },
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return Order.fromJson(data);
    }

    if (response.containsKey('id')) {
      return Order.fromJson(response);
    }

    throw ApiException('Không nhận được dữ liệu đơn hàng từ server.');
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

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return Order.fromJson(data);
    }

    return Order.fromJson(response);
  }

  Future<List<Order>> getSellerOrders({required String userId}) async {
    final response = await _apiClient.getList(
      ApiConfig.sellerOrdersEndpoint,
      extraHeaders: {'X-User-Id': userId},
    );

    return response.map(Order.fromJson).toList();
  }

  Future<Order> acceptOrder({
    required String userId,
    required String orderId,
  }) async {
    final response = await _apiClient.put(
      ApiConfig.orderAcceptEndpoint(orderId),
      extraHeaders: {'X-User-Id': userId},
    );

    return _parseOrderResponse(response);
  }

  Future<Order> completeOrder({
    required String userId,
    required String orderId,
  }) async {
    final response = await _apiClient.put(
      ApiConfig.orderCompleteEndpoint(orderId),
      extraHeaders: {'X-User-Id': userId},
    );

    return _parseOrderResponse(response);
  }

  Order _parseOrderResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return Order.fromJson(data);
    }

    if (response.containsKey('id')) {
      return Order.fromJson(response);
    }

    throw ApiException('Không nhận được dữ liệu đơn hàng từ server.');
  }
}
