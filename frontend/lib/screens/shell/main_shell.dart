import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import '../cart/cart_screen.dart';
import '../chat/chat_history_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _profileKey = GlobalKey<ProfileScreenState>();
  final _chatKey = GlobalKey<ChatHistoryScreenState>();
  int _chatUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
      _loadUnreadNotifications();
      _loadChatUnreadCount();
    });
  }

  Future<void> _loadChatUnreadCount() async {
    await _chatKey.currentState?.loadRooms();
    if (!mounted) {
      return;
    }

    setState(() {
      _chatUnreadCount = _chatKey.currentState?.totalUnreadCount ?? 0;
    });
  }

  Future<void> _loadUnreadNotifications() async {
    final userId = context.read<AuthProvider>().user?.id;
    await context.read<NotificationProvider>().loadUnreadCount(userId);
  }

  Future<void> _loadCart() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    await context.read<CartProvider>().loadCart(userId);
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);

    if (index == 1) {
      _loadCart();
    }

    if (index == 2) {
      _loadChatUnreadCount();
    }

    if (index == 3) {
      _profileKey.currentState?.loadOrderStats();
    }
  }

  void _openSellScreen() {
    Navigator.of(context).pushNamed(AppRoutes.sell);
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().totalQuantity;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          CartScreen(
            embeddedInShell: true,
            onStartShopping: () => _onTabSelected(0),
          ),
          ChatHistoryScreen(key: _chatKey),
          ProfileScreen(key: _profileKey),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 12),
        child: FloatingActionButton(
          onPressed: _openSellScreen,
          elevation: 4,
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      ),
      bottomNavigationBar: _AppBottomNavBar(
        currentIndex: _currentIndex,
        cartBadgeCount: cartCount,
        chatBadgeCount: _chatUnreadCount,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

class _AppBottomNavBar extends StatelessWidget {
  const _AppBottomNavBar({
    required this.currentIndex,
    required this.cartBadgeCount,
    required this.chatBadgeCount,
    required this.onTabSelected,
  });

  final int currentIndex;
  final int cartBadgeCount;
  final int chatBadgeCount;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.gray200.withValues(alpha: 0.8))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          height: 64,
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: AppStrings.navHome,
                isActive: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _NavItem(
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart,
                label: AppStrings.navCart,
                isActive: currentIndex == 1,
                badgeCount: cartBadgeCount,
                onTap: () => onTabSelected(1),
              ),
              const SizedBox(width: 56),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: AppStrings.navChat,
                isActive: currentIndex == 2,
                badgeCount: chatBadgeCount,
                onTap: () => onTabSelected(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: AppStrings.navProfile,
                isActive: currentIndex == 3,
                onTap: () => onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.gray400;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, size: 24, color: color),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.0,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
