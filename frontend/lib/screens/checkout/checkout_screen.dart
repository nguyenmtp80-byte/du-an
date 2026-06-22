import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_client.dart';
import '../../services/order_api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/order_detail_sheet.dart';
import '../../widgets/screen_header.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _orderApiService = OrderApiService();

  String _paymentMethod = 'CASH';
  bool _isSubmitting = false;
  bool _isSuccess = false;
  Order? _placedOrder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      _nameController.text = user?.fullName ?? '';
      _phoneController.text = user?.phone ?? '';
      _locationController.text = 'Thư viện chính - Cổng trước, gần quán cà phê';

      final userId = user?.id;
      if (userId != null && userId.isNotEmpty) {
        context.read<CartProvider>().loadCart(userId);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _cartSummaryTitle(List<CartItem> items) {
    if (items.isEmpty) {
      return 'Đơn hàng';
    }

    if (items.length == 1) {
      return items.first.productName;
    }

    return '${items.first.productName} +${items.length - 1} SP';
  }

  Future<void> _openCartPreview() async {
    final cartProvider = context.read<CartProvider>();
    if (cartProvider.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CartPreviewSheet(cart: cartProvider.cart),
    );
  }

  Future<void> _openPlacedOrderDetail() async {
    final order = _placedOrder;
    final userId = context.read<AuthProvider>().user?.id;

    if (order == null || userId == null || userId.isEmpty) {
      return;
    }

    try {
      final detail = await _orderApiService.getOrderDetail(
        userId: userId,
        orderId: order.id,
      );

      if (!mounted) {
        return;
      }

      await showOrderDetailSheet(context: context, order: detail);
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final userId = auth.user?.id;

    if (userId == null || userId.isEmpty) {
      _showMessage('Vui lòng đăng nhập để đặt hàng.');
      return;
    }

    if (cart.isEmpty) {
      _showMessage('Giỏ hàng trống, không thể đặt hàng.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final createdOrder = await _orderApiService.createOrder(
        userId: userId,
        paymentMethod: _paymentMethod,
        deliveryInfo: {
          'receiverName': _nameController.text.trim(),
          'receiverPhone': _phoneController.text.trim(),
          'deliveryLocation': _locationController.text.trim(),
          'notes': _notesController.text.trim(),
        },
      );

      final orderDetail = await _orderApiService.getOrderDetail(
        userId: userId,
        orderId: createdOrder.id,
      );

      cart.clearLocalCart();

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
        _placedOrder = orderDetail;
      });

      await Future<void>.delayed(const Duration(seconds: 3));

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMessage('Không thể tạo đơn hàng. Vui lòng thử lại.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess && _placedOrder != null) {
      final order = _placedOrder!;

      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 40,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đặt hàng thành công!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Người bán đã được thông báo. Kiểm tra tin nhắn để hẹn giao nhận.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.gray500, height: 1.5),
                ),
                const SizedBox(height: 24),
                OrderSummaryCard(
                  title: orderDisplayTitle(order),
                  totalAmount: order.totalAmount,
                  subtitle: 'Mã đơn: ${order.id}',
                  onViewDetail: _openPlacedOrderDetail,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          const ScreenHeader(title: 'Thanh toán'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionCard(
                      title: 'Địa điểm gặp mặt',
                      icon: Icons.location_on_outlined,
                      child: Column(
                        children: [
                          AuthTextField(
                            controller: _nameController,
                            hintText: 'Họ tên người nhận',
                            prefixIcon: Icons.person_outline,
                            validator: Validators.fullName,
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _phoneController,
                            hintText: 'Số điện thoại',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: Validators.phone,
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _locationController,
                            hintText: 'Địa điểm giao dịch trong trường',
                            prefixIcon: Icons.place_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập địa điểm gặp mặt';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _notesController,
                            hintText: 'Ghi chú (tuỳ chọn)',
                            prefixIcon: Icons.notes_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Tóm tắt đơn hàng',
                      icon: Icons.receipt_long_outlined,
                      child: cart.isEmpty
                          ? const Text(
                              'Giỏ hàng trống.',
                              style: TextStyle(color: AppColors.gray500),
                            )
                          : OrderSummaryCard(
                              title: _cartSummaryTitle(cart.items),
                              totalAmount: cart.totalAmount,
                              subtitle: '${cart.totalItems} sản phẩm trong giỏ',
                              onViewDetail: _openCartPreview,
                            ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Phương thức thanh toán',
                      icon: Icons.credit_card_outlined,
                      child: Column(
                        children: [
                          _PaymentOption(
                            label: 'Tiền mặt',
                            subtitle: 'Thanh toán khi gặp mặt',
                            value: 'CASH',
                            groupValue: _paymentMethod,
                            onChanged: (value) =>
                                setState(() => _paymentMethod = value!),
                          ),
                          const SizedBox(height: 8),
                          _PaymentOption(
                            label: 'Chuyển khoản',
                            subtitle: 'Chuyển khoản ngân hàng (demo)',
                            value: 'BANK_TRANSFER',
                            groupValue: _paymentMethod,
                            onChanged: (value) =>
                                setState(() => _paymentMethod = value!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.paddingOf(context).bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.gray200.withValues(alpha: 0.8))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray500,
                  ),
                ),
                Text(
                  formatPrice(cart.totalAmount),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _placeOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Đặt hàng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPreviewSheet extends StatelessWidget {
  const _CartPreviewSheet({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
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
            'Chi tiết giỏ hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: cart.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = cart.items[index];

                return Container(
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
                              'SL: ${item.quantity} × ${formatPrice(item.productPrice)}',
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                formatPrice(cart.totalAmount),
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
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return Material(
      color: isSelected ? AppColors.primaryLight : AppColors.gray50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.gray200,
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
