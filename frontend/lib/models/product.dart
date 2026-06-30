import '../config/api_config.dart';

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
      imageUrl: _resolveUrl(json['imageUrl'] as String? ?? json['image_url'] as String? ?? ''),
      displayOrder: json['displayOrder'] as int? ?? json['display_order'] as int?,
    );
  }

  /// Resolve relative paths (e.g. /uploads/...) to full backend URL
  static String _resolveUrl(String url) {
    if (url.startsWith('/')) {
      return '${ApiConfig.baseUploadUrl}$url';
    }
    return url;
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
    this.quantity = 0,
    this.description,
    this.locationName,
    this.latitude,
    this.longitude,
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
  final int quantity;
  final String? locationName;
  final double? latitude;
  final double? longitude;
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

  bool get isAvailable =>
      status.toLowerCase() == 'available' && quantity > 0;

  bool get hasMapLocation => latitude != null && longitude != null;

  factory Product.fromJson(Map<String, dynamic> json) {
    final sellerJson = json['seller'];

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['title'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: _parsePrice(json['price']),
      categoryName: json['category'] as String? ??
          json['categoryName'] as String? ??
          json['category_name'] as String? ??
          '',
      condition: json['condition']?.toString() ?? '',
      status: json['status']?.toString() ?? 'available',
      quantity: json['quantity'] as int? ?? 0,
      locationName: json['locationName'] as String? ?? json['location_name'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      images: _parseImages(json),
      seller: sellerJson is Map<String, dynamic>
          ? SellerInfo.fromJson(sellerJson)
          : _sellerFromFlatFields(json),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  static List<ProductImage> _parseImages(Map<String, dynamic> json) {
    final imageUrls = json['imageUrls'] ?? json['image_urls'];
    if (imageUrls is List) {
      return imageUrls.asMap().entries.map((entry) {
        return ProductImage(
          id: 'img-${entry.key}',
          imageUrl: ProductImage._resolveUrl(entry.value.toString()),
          displayOrder: entry.key + 1,
        );
      }).toList();
    }

    final imagesJson = json['images'];
    if (imagesJson is List) {
      return imagesJson
          .whereType<Map>()
          .map((item) => ProductImage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return const [];
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

  static double? _parseDouble(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
