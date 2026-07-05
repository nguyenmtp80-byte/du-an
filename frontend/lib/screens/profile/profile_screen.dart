import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/order_api_service.dart';
import '../../theme/app_theme.dart';
import '../../repositories/product_repository.dart';
import '../../utils/order_stats.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _orderApiService = OrderApiService();
  final _productRepository = ProductRepository();

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
      final results = await Future.wait([
        _orderApiService.getUserOrders(userId: userId),
        _orderApiService.getSellerOrders(userId: userId),
        _productRepository.fetchMyListings(userId),
      ]);

      if (!mounted) {
        return;
      }

      final buyerOrders = results[0] as List<Order>;
      final sellerOrders = results[1] as List<Order>;
      final listings = results[2] as List<Product>;

      setState(() {
        _soldItemCount = countSoldItemQuantity(sellerOrders);
        _boughtItemCount = countBoughtItemQuantity(buyerOrders);
        _pendingSellerCount = countPendingSellerOrders(sellerOrders);
        _buyerItemCount = _boughtItemCount;
        _soldOrderItemCount = countSoldOrderItemQuantity(sellerOrders);
        _listingProductCount = listings.length;
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.initial,
    required this.onLogout,
    required this.isLoggingOut,
    required this.soldCount,
    required this.boughtCount,
    required this.pendingCount,
  });

  final String displayName;
  final String email;
  final String initial;
  final VoidCallback onLogout;
  final bool isLoggingOut;
  final String soldCount;
  final String boughtCount;
  final String pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + 24,
        24,
        32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33F97316),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🎓', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Sinh viên đã xác minh',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: isLoggingOut ? null : onLogout,
                tooltip: 'Đăng xuất',
                icon: isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(value: soldCount, label: 'Đã bán'),
                ),
                Expanded(
                  child: _StatItem(value: boughtCount, label: 'Đã mua'),
                ),
                Expanded(
                  child: _StatItem(value: pendingCount, label: 'Chờ xác nhận'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.labelColor,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final Color? labelColor;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? AppColors.gray900,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.gray400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
