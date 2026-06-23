import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/order_api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/order_detail_sheet.dart';
import '../../widgets/screen_header.dart';

/// Danh sách đơn đã xác nhận / hoàn tất mà user đã bán.
class SoldOrdersScreen extends StatefulWidget {
  const SoldOrdersScreen({super.key});

  @override
  State<SoldOrdersScreen> createState() => _SoldOrdersScreenState();
}

class _SoldOrdersScreenState extends State<SoldOrdersScreen> {
  final _orderApiService = OrderApiService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  bool _isSoldOrder(Order order) {
    final status = order.status.toUpperCase();
    return status == 'APPROVED' || status == 'COMPLETED';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

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
        _orders = orders.where(_isSoldOrder).toList();
        _isLoading = false;
      });
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          const ScreenHeader(title: 'Đơn hàng đã bán'),
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

    if (_orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.check_circle_outline, size: 56, color: AppColors.gray400),
          SizedBox(height: 16),
          Text(
            'Chưa có đơn đã bán',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Các đơn đã xác nhận hoặc hoàn tất sẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray500, height: 1.5),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: _orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = _orders[index];

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openOrderDetail(order),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderDisplayTitle(order),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatPrice(order.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatOrderStatusLabel(order.status),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.gray400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
