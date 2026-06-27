import '../models/product.dart';

String summarizeProductLocations(List<Product> products) {
  final names = products
      .map((product) => product.locationName?.trim())
      .whereType<String>()
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();

  if (names.isEmpty) {
    return 'Chưa có thông tin địa điểm';
  }

  return names.join(' · ');
}

Product? firstProductWithMap(List<Product> products) {
  for (final product in products) {
    if (product.hasMapLocation) {
      return product;
    }
  }
  return null;
}

List<Product> uniqueProductsWithMap(List<Product> products) {
  final seen = <String>{};
  final result = <Product>[];

  for (final product in products) {
    if (!product.hasMapLocation || seen.contains(product.id)) {
      continue;
    }
    seen.add(product.id);
    result.add(product);
  }

  return result;
}
