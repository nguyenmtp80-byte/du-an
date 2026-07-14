import '../core/constants/api_config.dart';
import 'api_client.dart';

class CartApiService {
  CartApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getCart({required String userId}) {
    return _apiClient.get(
      ApiConfig.cartEndpoint,
      extraHeaders: {'X-User-Id': userId},
    );
  }

  Future<Map<String, dynamic>> addToCart({
    required String userId,
    required String productId,
    int quantity = 1,
  }) {
    return _apiClient.post(
      ApiConfig.cartAddEndpoint,
      extraHeaders: {'X-User-Id': userId},
      body: {
        'productId': productId,
        'quantity': quantity,
      },
    );
  }

  Future<Map<String, dynamic>> updateCartItem({
    required String userId,
    required String cartItemId,
    required int quantity,
  }) {
    return _apiClient.put(
      ApiConfig.cartUpdateEndpoint,
      extraHeaders: {'X-User-Id': userId},
      body: {
        'cartItemId': cartItemId,
        'quantity': quantity,
      },
    );
  }

  Future<Map<String, dynamic>> removeFromCart({
    required String userId,
    required String cartItemId,
  }) {
    return _apiClient.delete(
      ApiConfig.cartDeleteEndpoint(cartItemId),
      extraHeaders: {'X-User-Id': userId},
    );
  }
}
