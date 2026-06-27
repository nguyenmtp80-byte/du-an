import '../models/product.dart';

String formatPrice(double price) {
  final rounded = price.round();
  final text = rounded.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(text[i]);
  }

  return '${buffer.toString()}đ';
}

String formatProductCondition(String condition) {
  switch (condition.toUpperCase()) {
    case 'NEW':
      return 'Mới';
    case 'LIKE_NEW':
      return 'Như mới';
    case 'USED':
      return 'Đã sử dụng';
    default:
      return condition;
  }
}

String formatProductStatus(String status) {
  switch (status.toUpperCase()) {
    case 'AVAILABLE':
      return 'Còn hàng';
    case 'SOLD_OUT':
    case 'SOLD':
      return 'Hết hàng';
    default:
      return status;
  }
}

bool productConditionMatchesFilter(String productCondition, String filterCondition) {
  return productCondition.toUpperCase() == filterCondition.toUpperCase();
}

bool productStatusMatchesFilter(String productStatus, String filterStatus) {
  final product = productStatus.toLowerCase();
  final filter = filterStatus.toLowerCase();

  if (filter == 'available') {
    return product == 'available';
  }

  if (filter == 'sold' || filter == 'sold_out') {
    return product == 'sold' || product == 'sold_out';
  }

  return product == filter;
}

String formatRelativeDate(DateTime? dateTime) {
  if (dateTime == null) {
    return '';
  }

  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inDays == 0) {
    return 'Hôm nay';
  }

  if (diff.inDays == 1) {
    return 'Hôm qua';
  }

  if (diff.inDays < 7) {
    return '${diff.inDays} ngày trước';
  }

  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year;

  return '$day/$month/$year';
}

String sellerFirstName(Product product) {
  final name = product.sellerName.trim();
  if (name.isEmpty) {
    return 'Seller';
  }

  return name.split(' ').first;
}
