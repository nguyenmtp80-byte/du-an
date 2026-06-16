import '../config/api_config.dart';
import 'api_client.dart';

class ProductApiService {
  ProductApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> fetchProducts({
    String? search,
    String? category,
    String? status,
    double? minPrice,
    double? maxPrice,
  }) async {
    final query = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      query['category'] = category;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (minPrice != null) {
      query['minPrice'] = minPrice.round().toString();
    }
    if (maxPrice != null) {
      query['maxPrice'] = maxPrice.round().toString();
    }

    return _apiClient.getList(
      ApiConfig.productsEndpoint,
      queryParameters: query.isEmpty ? null : query,
    );
  }

  Future<Map<String, dynamic>> fetchProductDetail(String productId) {
    return _apiClient.get(ApiConfig.productDetailEndpoint(productId));
  }
}
