class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.quantity,
    required this.subtotal,
  });

  final String id;
  final String productId;
  final String productName;
  final double productPrice;
  final String productImage;
  final int quantity;
  final double subtotal;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['cartId']?.toString() ?? json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] as String? ?? '',
      productPrice: _parseAmount(json['productPrice']),
      productImage: json['productImage'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      subtotal: _parseAmount(json['subtotal']),
    );
  }

  static double _parseAmount(Object? value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}

class Cart {
  const Cart({
    required this.cartId,
    required this.items,
    required this.totalItems,
    required this.totalAmount,
  });

  final String cartId;
  final List<CartItem> items;
  final int totalItems;
  final double totalAmount;

  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];

    return Cart(
      cartId: json['cartId']?.toString() ?? json['userId']?.toString() ?? '',
      items: itemsJson is List
          ? itemsJson
              .whereType<Map>()
              .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      totalItems: json['totalItems'] as int? ?? 0,
      totalAmount: CartItem._parseAmount(json['totalAmount']),
    );
  }

  static Cart empty() => const Cart(
        cartId: '',
        items: [],
        totalItems: 0,
        totalAmount: 0,
      );
}
