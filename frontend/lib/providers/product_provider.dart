import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductRepository? productRepository})
      : _productRepository = productRepository ?? ProductRepository();

  final ProductRepository _productRepository;

  static const _favoritesKey = 'favorite_product_ids';

  List<Product> _products = [];
  Product? _selectedProduct;
  Set<String> _favoriteIds = {};
  bool _isLoadingList = false;
  bool _isLoadingDetail = false;
  String? _listError;
  String? _detailError;
  bool _isUsingDetailFallback = false;

  String _searchQuery = '';
  String _activeCategory = 'All';
  String? _statusFilter;
  double? _minPrice;
  double? _maxPrice;

  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get listError => _listError;
  String? get detailError => _detailError;
  bool get isUsingDetailFallback => _isUsingDetailFallback;
  String get searchQuery => _searchQuery;
  String get activeCategory => _activeCategory;
  String? get statusFilter => _statusFilter;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  List<String> get categories {
    final names = _products
        .map((product) => product.categoryName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['All', ...names];
  }

  List<Product> get filteredProducts {
    return _products.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _activeCategory == 'All' ||
          product.categoryName == _activeCategory;

      final matchesStatus = _statusFilter == null ||
          product.status.toUpperCase() == _statusFilter!.toUpperCase();

      final matchesMinPrice =
          _minPrice == null || product.price >= _minPrice!;

      final matchesMaxPrice =
          _maxPrice == null || product.price <= _maxPrice!;

      return matchesSearch &&
          matchesCategory &&
          matchesStatus &&
          matchesMinPrice &&
          matchesMaxPrice;
    }).toList();
  }

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<void> initialize() async {
    await _loadFavorites();
    await loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoadingList = true;
    _listError = null;
    notifyListeners();

    try {
      _products = await _productRepository.fetchProducts(
        search: _searchQuery,
        category: _activeCategory,
        status: _statusFilter,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
      _listError = null;
      _isUsingDetailFallback = false;
    } on ApiException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405) {
        _products = await _productRepository.fetchProductsFromDetails(
          ApiConfig.devProductIds,
        );
        _isUsingDetailFallback = _products.isNotEmpty;
        _listError = _products.isEmpty ? _mapListError(error) : null;
      } else {
        _listError = error.message;
        _products = [];
        _isUsingDetailFallback = false;
      }
    } catch (_) {
      _listError = 'Không thể tải danh sách sản phẩm. Vui lòng thử lại.';
      _products = [];
      _isUsingDetailFallback = false;
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  Future<void> refreshProducts() => loadProducts();

  Future<Product?> loadProductDetail(String productId) async {
    _isLoadingDetail = true;
    _detailError = null;
    _selectedProduct = null;
    notifyListeners();

    try {
      _selectedProduct = await _productRepository.fetchProductDetail(productId);
      _detailError = null;
      return _selectedProduct;
    } on ApiException catch (error) {
      _detailError = error.message;
      return null;
    } catch (_) {
      _detailError = 'Không thể tải chi tiết sản phẩm. Vui lòng thử lại.';
      return null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setActiveCategory(String category) {
    _activeCategory = category;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setPriceRange({double? minPrice, double? maxPrice}) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    notifyListeners();
  }

  void clearFilters() {
    _activeCategory = 'All';
    _statusFilter = null;
    _minPrice = null;
    _maxPrice = null;
    notifyListeners();
  }

  Future<void> toggleFavorite(String productId) async {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }

    notifyListeners();
    await _saveFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_favoritesKey);

    if (raw == null) {
      return;
    }

    _favoriteIds = raw.toSet();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
  }

  String _mapListError(ApiException error) {
    if (error.statusCode == 404 || error.statusCode == 405) {
      return 'Backend chưa có API GET /api/products.\n'
          'Nhờ team BE thêm endpoint danh sách sản phẩm.';
    }

    return error.message;
  }
}
