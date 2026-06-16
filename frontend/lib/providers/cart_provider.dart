import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../services/api_client.dart';
import '../services/cart_api_service.dart';

class CartProvider extends ChangeNotifier {
  CartProvider({CartApiService? cartApiService})
      : _cartApiService = cartApiService ?? CartApiService();

  final CartApiService _cartApiService;

  Cart _cart = Cart.empty();
  bool _isLoading = false;
  bool _isAdding = false;
  bool _isUpdating = false;
  String? _errorMessage;

  Cart get cart => _cart;
  List<CartItem> get items => _cart.items;
  int get totalItems => _cart.totalItems;
  double get totalAmount => _cart.totalAmount;
  bool get isEmpty => _cart.isEmpty;
  bool get isLoading => _isLoading;
  bool get isAdding => _isAdding;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  void _applyCartResponse(Map<String, dynamic> response) {
    _cart = Cart.fromJson(response);
  }

  Future<void> loadCart(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartApiService.getCart(userId: userId);
      _applyCartResponse(response);
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _cart = Cart.empty();
    } catch (_) {
      _errorMessage = 'Không thể tải giỏ hàng. Vui lòng thử lại.';
      _cart = Cart.empty();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart({
    required String userId,
    required String productId,
    int quantity = 1,
  }) async {
    _isAdding = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartApiService.addToCart(
        userId: userId,
        productId: productId,
        quantity: quantity,
      );
      _applyCartResponse(response);
      _isAdding = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _isAdding = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Không thể thêm vào giỏ hàng. Vui lòng thử lại.';
      _isAdding = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateQuantity({
    required String userId,
    required CartItem item,
    required int delta,
  }) async {
    final newQuantity = item.quantity + delta;

    if (newQuantity <= 0) {
      await removeItem(userId: userId, cartItemId: item.id);
      return;
    }

    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartApiService.updateCartItem(
        userId: userId,
        cartItemId: item.id,
        quantity: newQuantity,
      );
      _applyCartResponse(response);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Không thể cập nhật số lượng.';
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> removeItem({
    required String userId,
    required String cartItemId,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartApiService.removeFromCart(
        userId: userId,
        cartItemId: cartItemId,
      );
      _applyCartResponse(response);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Không thể xóa sản phẩm khỏi giỏ.';
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void clearLocalCart() {
    _cart = Cart.empty();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
