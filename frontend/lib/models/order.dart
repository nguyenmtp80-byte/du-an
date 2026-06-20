class OrderItem {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: _parseAmount(json['unitPrice']),
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

class Order {
  const Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.shippingNote,
    this.items = const [],
    this.createdAt,
  });

  final String id;
  final String buyerId;
  final String sellerId;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String? shippingNote;
  final List<OrderItem> items;
  final DateTime? createdAt;

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];

    return Order(
      id: json['id']?.toString() ?? '',
      buyerId: json['buyerId']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      totalAmount: OrderItem._parseAmount(json['totalAmount']),
      status: json['status']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      shippingNote: json['shippingNote'] as String?,
      items: itemsJson is List
          ? itemsJson
              .whereType<Map>()
              .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
