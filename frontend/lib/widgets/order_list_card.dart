import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../core/themes/app_theme.dart';
import '../utils/formatters.dart';
import 'order_detail_sheet.dart';

enum OrderListTab { all, approved, completed, cancelled }

const orderListTabs = <OrderListTab>[
  OrderListTab.all,
  OrderListTab.approved,
  OrderListTab.completed,
  OrderListTab.cancelled,
];

String orderListTabLabel(OrderListTab tab) {
  switch (tab) {
    case OrderListTab.all:
      return 'Tất cả';
    case OrderListTab.approved:
      return 'Đã xác nhận';
    case OrderListTab.completed:
      return 'Đã hoàn tất';
    case OrderListTab.cancelled:
      return 'Đã hủy';
  }
}

bool orderMatchesListTab(Order order, OrderListTab tab) {
  final status = order.status.toUpperCase();
  switch (tab) {
    case OrderListTab.all:
      return true;
    case OrderListTab.approved:
      return status == 'APPROVED' ||
          status == 'CONFIRMED' ||
          status == 'PAID';
    case OrderListTab.completed:
      return status == 'COMPLETED' || status == 'DELIVERED';
    case OrderListTab.cancelled:
      return status == 'CANCELLED';
  }
}

List<Order> filterAndSortOrders(List<Order> orders, OrderListTab tab) {
  return orders.where((order) => orderMatchesListTab(order, tab)).toList()
    ..sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
}

Color orderStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
    case 'DELIVERED':
      return AppColors.primary;
    case 'CANCELLED':
      return AppColors.gray500;
    default:
      return AppColors.gray700;
  }
}

class OrderListTabBar extends StatelessWidget {
  const OrderListTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final OrderListTab selectedTab;
  final ValueChanged<OrderListTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: orderListTabs.map((tab) {
            final isSelected = tab == selectedTab;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => onTabSelected(tab),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    orderListTabLabel(tab),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.gray700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class OrderListCard extends StatelessWidget {
  const OrderListCard({
    super.key,
    required this.order,
    required this.productCache,
    required this.headerLabel,
    required this.onOpenDetail,
    this.headerIcon = Icons.storefront_outlined,
  });

  final Order order;
  final Map<String, Product> productCache;
  final String headerLabel;
  final VoidCallback onOpenDetail;
  final IconData headerIcon;

  int get _itemCount =>
      order.items.fold<int>(0, (sum, item) => sum + item.quantity);

  OrderItem? get _primaryItem =>
      order.items.isNotEmpty ? order.items.first : null;

  Product? get _primaryProduct {
    final productId = _primaryItem?.productId;
    if (productId == null || productId.isEmpty) {
      return null;
    }
    return productCache[productId];
  }

  @override
  Widget build(BuildContext context) {
    final primaryItem = _primaryItem;
    final thumbnailUrl = _primaryProduct?.thumbnailUrl ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(headerIcon, size: 18, color: AppColors.gray500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      headerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  Text(
                    formatOrderStatusLabel(order.status),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: orderStatusColor(order.status),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.gray200),
              ),
              if (primaryItem != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: AppColors.gray50,
                        child: thumbnailUrl.isEmpty
                            ? const Icon(
                                Icons.image_outlined,
                                color: AppColors.gray400,
                              )
                            : Image.network(
                                thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.gray400,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  orderDisplayTitle(order),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ),
                              Text(
                                'x${primaryItem.quantity}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatPrice(primaryItem.unitPrice),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Text(
                  orderDisplayTitle(order),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Tổng số tiền ($_itemCount sản phẩm): ${formatPrice(order.totalAmount)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: onOpenDetail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Chi tiết đơn',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
