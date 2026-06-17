import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/screen_header.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    this.embeddedInShell = false,
    this.onStartShopping,
  });

  final bool embeddedInShell;
  final VoidCallback? onStartShopping;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCart());
  }

  Future<void> _loadCart() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    await context.read<CartProvider>().loadCart(userId);
  }

  void _openCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CheckoutScreen()),
    );
  }

  void _goShopping() {
    if (widget.onStartShopping != null) {
      widget.onStartShopping!();
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final userId = context.watch<AuthProvider>().user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Giỏ hàng',
            showBackButton: !widget.embeddedInShell,
          ),
          Expanded(
            child: cart.isLoading
                ? const Center(child: CircularProgressIndicator())
                : cart.isEmpty
                    ? _EmptyCart(onStartShopping: _goShopping)
                    : RefreshIndicator(
                        onRefresh: _loadCart,
                        color: AppColors.primary,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                          children: [
                            if (cart.errorMessage != null) ...[
                              _ErrorBanner(message: cart.errorMessage!),
                              const SizedBox(height: 16),
                            ],
                            ...cart.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _CartItemCard(
                                  item: item,
                                  isUpdating: cart.isUpdating,
                                  onRemove: () => cart.removeItem(
                                    userId: userId,
                                    cartItemId: item.id,
                                  ),
                                  onIncrease: () => cart.updateQuantity(
                                    userId: userId,
                                    item: item,
                                    delta: 1,
                                  ),
                                  onDecrease: () => cart.updateQuantity(
                                    userId: userId,
                                    item: item,
                                    delta: -1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
          if (!cart.isEmpty && !cart.isLoading)
            _CheckoutBar(
              totalAmount: cart.totalAmount,
              itemCount: cart.items.length,
              onCheckout: _openCheckout,
              extraBottomPadding: widget.embeddedInShell ? 72 : 0,
            ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onStartShopping});

  final VoidCallback onStartShopping;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Giỏ hàng trống',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn chưa thêm sản phẩm nào vào giỏ hàng.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.gray500),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onStartShopping,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Mua sắm ngay',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.isUpdating,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
  });

  final CartItem item;
  final bool isUpdating;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.productImage.isNotEmpty
                ? Image.network(
                    item.productImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: isUpdating ? null : onRemove,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.gray400,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      formatPrice(item.productPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    _QuantityControl(
                      quantity: item.quantity,
                      isUpdating: isUpdating,
                      onIncrease: onIncrease,
                      onDecrease: onDecrease,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.gray50,
      child: const Icon(Icons.image_outlined, color: AppColors.gray400),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.isUpdating,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final bool isUpdating;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          _QtyButton(
            icon: Icons.remove,
            onTap: isUpdating ? null : onDecrease,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add,
            onTap: isUpdating ? null : onIncrease,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(icon, size: 14, color: AppColors.gray700),
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.totalAmount,
    required this.itemCount,
    required this.onCheckout,
    this.extraBottomPadding = 0,
  });

  final double totalAmount;
  final int itemCount;
  final VoidCallback onCheckout;
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.paddingOf(context).bottom + 20 + extraBottomPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tạm tính',
                style: TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
              Text(
                formatPrice(totalAmount),
                style: const TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF3F4F6)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              Text(
                formatPrice(totalAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCheckout,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Thanh toán ($itemCount)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
      ),
    );
  }
}
