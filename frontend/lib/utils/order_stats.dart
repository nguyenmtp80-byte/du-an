import '../models/order.dart';
import '../models/product.dart';

int countOrderItemQuantity(List<Order> orders) {
  return orders.fold<int>(
    0,
    (sum, order) =>
        sum + order.items.fold<int>(0, (itemSum, item) => itemSum + item.quantity),
  );
}

int countSoldItemQuantity(List<Order> sellerOrders) {
  return countOrderItemQuantity(
    sellerOrders
        .where((order) => order.status.toUpperCase() == 'COMPLETED')
        .toList(),
  );
}

int countBoughtItemQuantity(List<Order> buyerOrders) {
  return countOrderItemQuantity(buyerOrders);
}

int countSoldOrderItemQuantity(List<Order> sellerOrders) {
  return countOrderItemQuantity(
    sellerOrders.where((order) {
      final status = order.status.toUpperCase();
      return status == 'APPROVED' || status == 'COMPLETED';
    }).toList(),
  );
}

int countPendingSellerOrders(List<Order> sellerOrders) {
  return sellerOrders
      .where((order) => order.status.toUpperCase() == 'PENDING')
      .length;
}

int countListedProducts(List<Product> products, String sellerId) {
  return products.where((product) => product.seller?.id == sellerId).length;
}
