import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/order_repository.dart';
import '../../services/api_client.dart';
import '../../core/themes/app_theme.dart';

part 'widgets/profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _orderRepository = OrderRepository();

  int _soldItemCount = 0;
  int _boughtItemCount = 0;
  int _pendingSellerCount = 0;
  int _buyerItemCount = 0;
  int _soldOrderItemCount = 0;
  int _listingProductCount = 0;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadOrderStats());
  }

  Future<void> loadOrderStats() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    setState(() => _isLoadingStats = true);

    try {
      final stats = await _orderRepository.fetchProfileStats(userId);
      if (!mounted) {
        return;
      }

      setState(() {
        _soldItemCount = stats.soldItemCount;
        _boughtItemCount = stats.boughtItemCount;
        _pendingSellerCount = stats.pendingSellerCount;
        _buyerItemCount = stats.boughtItemCount;
        _soldOrderItemCount = stats.soldOrderItemCount;
        _listingProductCount = stats.listingProductCount;
        _isLoadingStats = false;
      });
    } on ApiException {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  String _statValue(int value) {
    if (_isLoadingStats) {
      return '…';
    }
    return '$value';
  }

  String _menuCount(int value) {
    if (_isLoadingStats) {
      return '…';
    }
    return '$value SP';
  }

  String _productCount(int value) {
    if (_isLoadingStats) {
      return '…';
    }
    return '$value SP';
  }

  void _openOrders(BuildContext context) {
    Navigator.of(context)
        .pushNamed(AppRoutes.myOrders)
        .then((_) => loadOrderStats());
  }

  void _openSoldOrders(BuildContext context) {
    Navigator.of(context)
        .pushNamed(AppRoutes.soldOrders)
        .then((_) => loadOrderStats());
  }

  void _openListings(BuildContext context) {
    Navigator.of(context)
        .pushNamed(AppRoutes.myListings)
        .then((_) => loadOrderStats());
  }

  void _openHelpCenter(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.helpCenter);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) {
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName = user?.displayName ?? 'Sinh viên';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          _ProfileHeader(
            displayName: displayName,
            email: user?.email ?? '',
            initial: initial,
            onLogout: () => _confirmLogout(context),
            isLoggingOut: auth.isLoading,
            soldCount: _statValue(_soldItemCount),
            boughtCount: _statValue(_boughtItemCount),
            pendingCount: _statValue(_pendingSellerCount),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadOrderStats,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                children: [
                  _ProfileMenuItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Đơn hàng mua',
                    trailing: _menuCount(_buyerItemCount),
                    onTap: () => _openOrders(context),
                  ),
                  const SizedBox(height: 12),
                _ProfileMenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Đơn hàng đã bán',
                  trailing: _menuCount(_soldOrderItemCount),
                  onTap: () => _openSoldOrders(context),
                ),
                const SizedBox(height: 12),
                _ProfileMenuItem(
                  icon: Icons.storefront_outlined,
                  label: 'Sản phẩm đăng bán',
                  trailing: _productCount(_listingProductCount),
                  onTap: () => _openListings(context),
                ),
                  const SizedBox(height: 12),
                  _ProfileMenuItem(
                    icon: Icons.favorite_border,
                    label: 'Yêu thích',
                    trailing: '—',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _ProfileMenuItem(
                    icon: Icons.credit_card_outlined,
                    label: 'Phương thức thanh toán',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _ProfileMenuItem(
                    icon: Icons.help_outline,
                    label: 'Trung tâm trợ giúp',
                    onTap: () => _openHelpCenter(context),
                  ),
                  const SizedBox(height: 12),
                  _ProfileMenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Cài đặt',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _ProfileMenuItem(
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    labelColor: const Color(0xFFDC2626),
                    iconBackgroundColor: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFDC2626),
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
