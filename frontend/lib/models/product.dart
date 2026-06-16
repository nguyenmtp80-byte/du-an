class ProductImage {
  const ProductImage({
    required this.id,
    required this.imageUrl,
    this.displayOrder,
  });

  final String id;
  final String imageUrl;
  final int? displayOrder;

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
      displayOrder: json['displayOrder'] as int? ?? json['display_order'] as int?,
    );
  }
}

class SellerInfo {
  const SellerInfo({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryName,
    required this.condition,
    required this.status,
    this.description,
    this.images = const [],
    this.seller,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final double price;
  final String categoryName;
  final String condition;
  final String status;
  final List<ProductImage> images;
  final SellerInfo? seller;
  final DateTime? createdAt;

  String get thumbnailUrl {
    if (images.isEmpty) {
      return '';
    }

    final sorted = [...images]
      ..sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));

    return sorted.first.imageUrl;
  }

  String get sellerName => seller?.fullName ?? '';

  String? get sellerAvatar => seller?.avatarUrl;

  bool get isAvailable => status.toUpperCase() == 'AVAILABLE';

  factory Product.fromJson(Map<String, dynamic> json) {
    final imagesJson = json['images'];
    final sellerJson = json['seller'];

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: _parsePrice(json['price']),
      categoryName: json['categoryName'] as String? ??
          json['category_name'] as String? ??
          '',
      condition: json['condition'] as String? ?? '',
      status: json['status'] as String? ?? 'AVAILABLE',
      images: imagesJson is List
          ? imagesJson
              .whereType<Map>()
              .map((item) => ProductImage.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      seller: sellerJson is Map<String, dynamic>
          ? SellerInfo.fromJson(sellerJson)
          : _sellerFromFlatFields(json),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  static SellerInfo? _sellerFromFlatFields(Map<String, dynamic> json) {
    final sellerId = json['sellerId'] ?? json['seller_id'];
    final sellerName = json['sellerName'] ?? json['seller_name'];

    if (sellerId == null && sellerName == null) {
      return null;
    }

    return SellerInfo(
      id: sellerId?.toString() ?? '',
      fullName: sellerName?.toString() ?? '',
      avatarUrl: json['sellerAvatar'] as String? ?? json['seller_avatar'] as String?,
    );
  }

  static double _parsePrice(Object? value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
