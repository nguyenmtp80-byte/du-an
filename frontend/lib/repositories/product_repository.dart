import 'dart:typed_data';

import 'package:http/http.dart' as http;

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
        continue;
      }
    }

    return products;
  }

  Future<List<Product>> fetchMyListings(String sellerId) async {
    final products = await fetchProducts();
    return products.where((product) => product.seller?.id == sellerId).toList();
  }

  Future<Product> fetchProductDetail(String productId) async {
    final response = await _productApiService.fetchProductDetail(productId);
    return Product.fromJson(response);
  }

  Future<Product> createProduct({
    required String userId,
    required String title,
    required String description,
    required int price,
    required String category,
    required String condition,
    required int quantity,
    String? locationName,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
  }) async {
    final response = await _productApiService.createProduct(
      userId: userId,
      body: {
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'condition': condition,
        'quantity': quantity,
        if (locationName != null && locationName.trim().isNotEmpty)
          'locationName': locationName.trim(),
        if (latitude != null && longitude != null) ...{
          'latitude': latitude,
          'longitude': longitude,
        },
        if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      },
    );

    return Product.fromJson(response);
  }

  Future<List<String>> uploadProductImages(List<Uint8List> imageBytesList) async {
    if (imageBytesList.isEmpty) {
      return [];
    }

    final apiClient = ApiClient();
    final multipartFiles = <http.MultipartFile>[];

    for (var index = 0; index < imageBytesList.length; index++) {
      multipartFiles.add(
        http.MultipartFile.fromBytes(
          'files',
          imageBytesList[index],
          filename: 'product_$index.jpg',
        ),
      );
    }

    final response = await apiClient.uploadMultipart(
      ApiConfig.uploadImagesEndpoint,
      files: multipartFiles,
    );

    final urls = response['urls'];
    if (urls is List) {
      return urls.map((url) => url.toString()).toList();
    }

    return [];
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
