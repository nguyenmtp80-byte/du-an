import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

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
    case 'CONFIRMED':
      return 'Đã xác nhận';
    case 'SHIPPED':
      return 'Đang giao';
    case 'DELIVERED':
      return 'Đã giao';
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
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _OrderDetailSheet(order: order),
  );
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.order});

  final Order order;

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
            'Mã đơn: ${order.id}',
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
                    value: formatOrderStatusLabel(order.status),
                  ),
                  _DetailRow(
                    label: 'Thanh toán',
                    value: formatPaymentMethodLabel(order.paymentMethod),
                  ),
                  if (order.shippingNote != null &&
                      order.shippingNote!.trim().isNotEmpty)
                    _DetailRow(label: 'Ghi chú', value: order.shippingNote!),
                  if (order.createdAt != null)
                    _DetailRow(
                      label: 'Ngày đặt',
                      value: formatRelativeDate(order.createdAt),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sản phẩm',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (order.items.isEmpty)
                    const Text(
                      'Không có sản phẩm trong đơn.',
                      style: TextStyle(color: AppColors.gray500, fontSize: 13),
                    )
                  else
                    ...order.items.map(
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
                        formatPrice(order.totalAmount),
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
