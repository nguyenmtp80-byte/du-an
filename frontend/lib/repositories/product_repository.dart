import '../config/api_config.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../services/product_api_service.dart';

class ProductRepository {
  ProductRepository({ProductApiService? productApiService})
      : _productApiService = productApiService ?? ProductApiService();

  final ProductApiService _productApiService;

  Future<List<Product>> fetchProducts({
    String? search,
    String? category,
    String? status,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final response = await _productApiService.fetchProducts(
        search: search,
        category: category,
        status: status,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );

      return response.map(Product.fromJson).toList();
    } on ApiException catch (error) {
      if (_shouldUseDetailFallback(error)) {
        return fetchProductsFromDetails(ApiConfig.devProductIds);
      }

      rethrow;
    }
  }

  Future<List<Product>> fetchProductsFromDetails(List<String> productIds) async {
    final products = <Product>[];

    for (final productId in productIds) {
      try {
        products.add(await fetchProductDetail(productId));
      } on ApiException {
        // Bỏ qua sản phẩm không tồn tại trong DB.
      }
    }

    return products;
  }

  Future<Product> fetchProductDetail(String productId) async {
    final response = await _productApiService.fetchProductDetail(productId);
    return Product.fromJson(response);
  }

  bool _shouldUseDetailFallback(ApiException error) {
    final code = error.statusCode;
    if (code == null) {
      return _looksLikeServerListFailure(error.message);
    }

    return code == 404 ||
        code == 405 ||
        code >= 500 ||
        _looksLikeServerListFailure(error.message);
  }

  bool _looksLikeServerListFailure(String message) {
    final lower = message.toLowerCase();
    return lower.contains('lỗi khi lấy danh sách sản phẩm') ||
        lower.contains('jdbc') ||
        lower.contains('column') ||
        lower.contains('does not exist');
  }
}
