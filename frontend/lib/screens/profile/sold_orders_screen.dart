import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/product_repository.dart';
import '../../services/api_client.dart';
import '../../services/order_api_service.dart';
import '../../core/themes/app_theme.dart';
import '../../widgets/order_detail_sheet.dart';
import '../../widgets/order_list_card.dart';
import '../../widgets/screen_header.dart';

class SoldOrdersScreen extends StatefulWidget {
  const SoldOrdersScreen({super.key});

  @override
  State<SoldOrdersScreen> createState() => _SoldOrdersScreenState();
}

class _SoldOrdersScreenState extends State<SoldOrdersScreen> {
  final _orderApiService = OrderApiService();
  final _productRepository = ProductRepository();

  List<Order> _orders = [];
  Map<String, Product> _productCache = {};
  bool _isLoading = false;
  String? _error;
  OrderListTab _selectedTab = OrderListTab.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  List<Order> get _filteredOrders =>
      filterAndSortOrders(_orders, _selectedTab);

  Future<void> _loadOrders() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _orderApiService.getSellerOrders(userId: userId);
      if (!mounted) {
        return;
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      await _loadProductCache(orders);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Không thể tải đơn hàng đã bán.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProductCache(List<Order> orders) async {
    final productIds = <String>{};
    for (final order in orders) {
      for (final item in order.items) {
        if (item.productId.isNotEmpty) {
          productIds.add(item.productId);
        }
      }
    }

    final cache = Map<String, Product>.from(_productCache);
    for (final productId in productIds) {
      if (cache.containsKey(productId)) {
        continue;
      }

      try {
        cache[productId] = await _productRepository.fetchProductDetail(productId);
      } on ApiException {
        continue;
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _productCache = cache);
    }
  }

  Future<void> _openOrderDetail(Order order) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    Order detail = order;

    if (order.items.isEmpty) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        detail = await _orderApiService.getOrderDetail(
          userId: userId,
          orderId: order.id,
        );
      } on ApiException catch (error) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message)),
          );
        }
        return;
      } catch (_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải chi tiết đơn hàng.')),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }

    if (!mounted) {
      return;
    }

    await showOrderDetailSheet(
      context: context,
      order: detail,
      enableSellerActions: true,
      orderApiService: _orderApiService,
      userId: userId,
      onOrderUpdated: _loadOrders,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          const ScreenHeader(title: 'Đơn hàng đã bán'),
          OrderListTabBar(
            selectedTab: _selectedTab,
            onTabSelected: (tab) => setState(() => _selectedTab = tab),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              color: AppColors.primary,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray700),
            ),
          ),
        ],
      );
    }

    final orders = _filteredOrders;

    if (orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.check_circle_outline, size: 56, color: AppColors.gray400),
          const SizedBox(height: 16),
          Text(
            _selectedTab == OrderListTab.all
                ? 'Chưa có đơn bán'
                : 'Không có đơn hàng trong mục này',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các đơn chờ xác nhận, đã xác nhận hoặc hoàn tất sẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray500, height: 1.5),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderListCard(
          order: order,
          productCache: _productCache,
          headerLabel: 'Người mua',
          headerIcon: Icons.person_outline,
          onOpenDetail: () => _openOrderDetail(order),
        );
      },
    );
  }
}
