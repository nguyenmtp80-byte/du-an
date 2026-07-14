import '../models/order.dart';
import '../models/product.dart';
import '../services/order_api_service.dart';
import '../utils/order_stats.dart';
import 'product_repository.dart';

class ProfileOrderStats {
  const ProfileOrderStats({
    required this.soldItemCount,
    required this.boughtItemCount,
    required this.pendingSellerCount,
    required this.soldOrderItemCount,
    required this.listingProductCount,
  });

  final int soldItemCount;
  final int boughtItemCount;
  final int pendingSellerCount;
  final int soldOrderItemCount;
  final int listingProductCount;
}

class OrderRepository {
  OrderRepository({
    OrderApiService? orderApiService,
    ProductRepository? productRepository,
  })  : _orderApiService = orderApiService ?? OrderApiService(),
        _productRepository = productRepository ?? ProductRepository();

  final OrderApiService _orderApiService;
  final ProductRepository _productRepository;

  Future<ProfileOrderStats> fetchProfileStats(String userId) async {
    final results = await Future.wait([
      _orderApiService.getUserOrders(userId: userId),
      _orderApiService.getSellerOrders(userId: userId),
      _productRepository.fetchMyListings(userId),
    ]);

    final buyerOrders = results[0] as List<Order>;
    final sellerOrders = results[1] as List<Order>;
    final listings = results[2] as List<Product>;
    final boughtItemCount = countBoughtItemQuantity(buyerOrders);

    return ProfileOrderStats(
      soldItemCount: countSoldItemQuantity(sellerOrders),
      boughtItemCount: boughtItemCount,
      pendingSellerCount: countPendingSellerOrders(sellerOrders),
      soldOrderItemCount: countSoldOrderItemQuantity(sellerOrders),
      listingProductCount: listings.length,
    );
  }
}
