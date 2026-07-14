import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/api_client.dart';
import '../../services/notification_api_service.dart';
import '../../services/order_api_service.dart';
import '../../core/themes/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/order_detail_sheet.dart';
import '../../widgets/screen_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationApiService = NotificationApiService();
  final _orderApiService = OrderApiService();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications =
          await _notificationApiService.getNotifications(userId: userId);
      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

      if (mounted) {
        await context.read<NotificationProvider>().loadUnreadCount(userId);
      }
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
        _error = 'Không thể tải thông báo.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openNotification(AppNotification notification) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    if (!notification.isRead) {
      try {
        await _notificationApiService.markAsRead(
          userId: userId,
          notificationId: notification.id,
        );
      } catch (_) {}
    }

    final orderId = notification.orderId;
    if (orderId == null || orderId.isEmpty) {
      await _loadNotifications();
      return;
    }

    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final order = await _orderApiService.getOrderDetail(
        userId: userId,
        orderId: orderId,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      final isSeller = order.sellerId == userId;
      final isBuyer = order.buyerId == userId;

      await showOrderDetailSheet(
        context: context,
        order: order,
        enableSellerActions: isSeller,
        enableBuyerActions: isBuyer,
        orderApiService: _orderApiService,
        userId: userId,
        onOrderUpdated: () async {
          await _loadNotifications();
          if (mounted) {
            await context.read<NotificationProvider>().loadUnreadCount(userId);
          }
        },
      );
      await _loadNotifications();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở chi tiết đơn hàng.')),
      );
    }
  }

  Future<void> _markAllRead() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    await _notificationApiService.markAllAsRead(userId: userId);
    await _loadNotifications();
    if (mounted) {
      await context.read<NotificationProvider>().loadUnreadCount(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Thông báo',
            showBackButton: widget.showBackButton,
            trailing: _notifications.any((item) => !item.isRead)
                ? TextButton(
                    onPressed: _markAllRead,
                    child: const Text('Đọc hết'),
                  )
                : null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              color: AppColors.primary,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
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

    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.notifications_none_outlined, size: 56, color: AppColors.gray400),
          SizedBox(height: 16),
          Text(
            'Chưa có thông báo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Thông báo đơn hàng sẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: _notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notification = _notifications[index];

        return Material(
          color: notification.isRead ? Colors.white : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openNotification(notification),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? AppColors.gray50
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: notification.isRead
                          ? AppColors.gray400
                          : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray500,
                            height: 1.4,
                          ),
                        ),
                        if (notification.createdAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            formatRelativeDate(notification.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
