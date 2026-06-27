import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../services/api_client.dart';
import '../services/order_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/product_location_utils.dart';
import 'location_map_sheet.dart';

String orderDisplayTitle(Order order) {
  if (order.items.isEmpty) {
    return 'Đơn hàng #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}';
  }

  if (order.items.length == 1) {
    return order.items.first.productName;
  }

  return '${order.items.first.productName} +${order.items.length - 1} SP';
}

String formatOrderStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return 'Chờ xác nhận';
    case 'APPROVED':
      return 'Đã xác nhận';
    case 'COMPLETED':
      return 'Đã hoàn tất';
    case 'CONFIRMED':
      return 'Đã xác nhận';
    case 'SHIPPED':
      return 'Đang giao';
    case 'DELIVERED':
      return 'Đã hoàn tất';
    case 'CANCELLED':
      return 'Đã hủy';
    default:
      return status;
  }
}

String formatPaymentMethodLabel(String method) {
  switch (method.toUpperCase()) {
    case 'CASH':
      return 'Tiền mặt';
    case 'BANK_TRANSFER':
      return 'Chuyển khoản';
    default:
      return method;
  }
}

Future<void> showOrderDetailSheet({
  required BuildContext context,
  required Order order,
  bool enableSellerActions = false,
  bool enableBuyerActions = false,
  OrderApiService? orderApiService,
  String? userId,
  VoidCallback? onOrderUpdated,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _OrderDetailSheet(
      order: order,
      enableSellerActions: enableSellerActions,
      enableBuyerActions: enableBuyerActions,
      orderApiService: orderApiService,
      userId: userId,
      onOrderUpdated: onOrderUpdated,
    ),
  );
}

class _OrderDetailSheet extends StatefulWidget {
  const _OrderDetailSheet({
    required this.order,
    this.enableSellerActions = false,
    this.enableBuyerActions = false,
    this.orderApiService,
    this.userId,
    this.onOrderUpdated,
  });

  final Order order;
  final bool enableSellerActions;
  final bool enableBuyerActions;
  final OrderApiService? orderApiService;
  final String? userId;
  final VoidCallback? onOrderUpdated;

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  late Order _order;
  bool _isSubmitting = false;
  bool _isLoadingProducts = false;
  List<Product> _orderProducts = [];
  final _productRepository = ProductRepository();

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadOrderProducts();
  }

  Future<void> _loadOrderProducts() async {
    if (_order.items.isEmpty) {
      return;
    }

    setState(() => _isLoadingProducts = true);

    final products = <Product>[];
    for (final item in _order.items) {
      if (item.productId.isEmpty) {
        continue;
      }

      try {
        products.add(await _productRepository.fetchProductDetail(item.productId));
      } on ApiException {
        // Bỏ qua sản phẩm không tải được.
      } catch (_) {
        // Bỏ qua sản phẩm không tải được.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _orderProducts = products;
      _isLoadingProducts = false;
    });
  }

  void _openProductMap(Product product) {
    if (!product.hasMapLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm chưa có tọa độ trên bản đồ.')),
      );
      return;
    }

    LocationMapSheet.viewLocation(
      context,
      latitude: product.latitude!,
      longitude: product.longitude!,
      locationLabel: product.locationName,
    );
  }

  bool get _canAccept =>
      widget.enableSellerActions && _order.status.toUpperCase() == 'PENDING';

  bool get _canComplete =>
      widget.enableSellerActions && _order.status.toUpperCase() == 'APPROVED';

  bool get _canCancel =>
      widget.enableBuyerActions && _order.status.toUpperCase() == 'PENDING';

  Future<void> _handleAccept() async {
    final userId = widget.userId;
    final api = widget.orderApiService;
    if (userId == null || api == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updated = await api.acceptOrder(userId: userId, orderId: _order.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _order = updated;
        _isSubmitting = false;
      });
      widget.onOrderUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác nhận đơn hàng.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xác nhận đơn hàng.')),
      );
    }
  }

  Future<void> _handleComplete() async {
    final userId = widget.userId;
    final api = widget.orderApiService;
    if (userId == null || api == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updated = await api.completeOrder(userId: userId, orderId: _order.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _order = updated;
        _isSubmitting = false;
      });
      widget.onOrderUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hoàn tất đơn hàng.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể hoàn tất đơn hàng.')),
      );
    }
  }

  Future<void> _handleCancel() async {
    final userId = widget.userId;
    final api = widget.orderApiService;
    if (userId == null || api == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updated = await api.cancelOrder(userId: userId, orderId: _order.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _order = updated;
        _isSubmitting = false;
      });
      widget.onOrderUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đơn hàng.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể hủy đơn hàng.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chi tiết đơn hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mã đơn: ${_order.id}',
            style: const TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    label: 'Trạng thái',
                    value: formatOrderStatusLabel(_order.status),
                  ),
                  _DetailRow(
                    label: 'Thanh toán',
                    value: formatPaymentMethodLabel(_order.paymentMethod),
                  ),
                  if (_order.shippingNote != null &&
                      _order.shippingNote!.trim().isNotEmpty)
                    _DetailRow(label: 'Ghi chú', value: _order.shippingNote!),
                  if (_order.createdAt != null)
                    _DetailRow(
                      label: 'Ngày đặt',
                      value: formatRelativeDate(_order.createdAt),
                    ),
                  if (_orderProducts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Địa điểm',
                      value: _isLoadingProducts
                          ? 'Đang tải...'
                          : summarizeProductLocations(_orderProducts),
                    ),
                    ...uniqueProductsWithMap(_orderProducts).map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.locationName ?? product.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _openProductMap(product),
                              icon: const Icon(
                                Icons.map_outlined,
                                color: AppColors.primary,
                              ),
                              tooltip: 'Xem bản đồ',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Sản phẩm',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_order.items.isEmpty)
                    const Text(
                      'Không có sản phẩm trong đơn.',
                      style: TextStyle(color: AppColors.gray500, fontSize: 13),
                    )
                  else
                    ..._order.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.gray900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'SL: ${item.quantity} × ${formatPrice(item.unitPrice)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatPrice(item.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng cộng',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray700,
                        ),
                      ),
                      Text(
                        formatPrice(_order.totalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_canAccept)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton(
                onPressed: _isSubmitting ? null : _handleAccept,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Xác nhận đơn'),
              ),
            ),
          if (_canComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton(
                onPressed: _isSubmitting ? null : _handleComplete,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Hoàn tất đơn'),
              ),
            ),
          if (_canCancel)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton(
                onPressed: _isSubmitting ? null : _handleCancel,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Hủy đơn'),
              ),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.gray900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.onViewDetail,
    this.subtitle,
  });

  final String title;
  final double totalAmount;
  final String? subtitle;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  formatPrice(totalAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewDetail,
            child: const Text(
              'Chi tiết',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
