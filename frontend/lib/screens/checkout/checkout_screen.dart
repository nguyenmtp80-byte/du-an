import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_client.dart';
import '../../services/order_api_service.dart';
import '../../repositories/product_repository.dart';
import '../../core/themes/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/product_location_utils.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/location_map_sheet.dart';
import '../../widgets/order_detail_sheet.dart';
import '../../widgets/screen_header.dart';

part 'widgets/checkout_form_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _orderApiService = OrderApiService();
  final _productRepository = ProductRepository();

  String _paymentMethod = 'CASH';
  bool _isSubmitting = false;
  bool _isSuccess = false;
  bool _isLoadingLocations = false;
  Order? _placedOrder;
  List<Product> _cartProducts = [];
  String _meetingLocationText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      _nameController.text = user?.fullName ?? '';
      _phoneController.text = user?.phone ?? '';

      final userId = user?.id;
      if (userId != null && userId.isNotEmpty) {
        context.read<CartProvider>().loadCart(userId).then((_) {
          if (mounted) {
            _loadProductLocations();
          }
        });
      }
    });
  }

  Future<void> _loadProductLocations() async {
    final cartItems = context.read<CartProvider>().cart.items;
    if (cartItems.isEmpty) {
      setState(() {
        _cartProducts = [];
        _meetingLocationText = '';
      });
      return;
    }

    setState(() => _isLoadingLocations = true);

    final products = <Product>[];
    for (final item in cartItems) {
      try {
        products.add(await _productRepository.fetchProductDetail(item.productId));
      } on ApiException {
        continue;
      } catch (_) {
        continue;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _cartProducts = products;
      _meetingLocationText = summarizeProductLocations(products);
      _isLoadingLocations = false;
    });
  }

  void _openMeetingLocationMap() {
    final product = firstProductWithMap(_cartProducts);
    if (product == null) {
      _showMessage('Sản phẩm chưa có tọa độ trên bản đồ.');
      return;
    }

    LocationMapSheet.viewLocation(
      context,
      latitude: product.latitude!,
      longitude: product.longitude!,
      locationLabel: product.locationName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
          'deliveryLocation': _meetingLocationText,
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

      if (_paymentMethod == 'BANK_TRANSFER_QR') {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.paymentQr,
          arguments: {
            AppRoutes.orderIdArg: orderDetail.id,
            'totalAmount': orderDetail.totalAmount,
          },
        );
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
                          _MeetingLocationField(
                            locationText: _meetingLocationText,
                            isLoading: _isLoadingLocations,
                            onViewMap: _openMeetingLocationMap,
                            hasMap: firstProductWithMap(_cartProducts) != null,
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
                            label: 'Quét mã QR VietQR',
                            subtitle: 'Quét mã QR bằng app ngân hàng để thanh toán',
                            value: 'BANK_TRANSFER_QR',
                            groupValue: _paymentMethod,
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0066B3).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.qr_code_2,
                                color: Color(0xFF0066B3),
                                size: 20,
                              ),
                            ),
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
                    : Text(
                        _paymentMethod == 'BANK_TRANSFER_QR'
                            ? 'Đặt hàng & thanh toán QR'
                            : 'Đặt hàng',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

