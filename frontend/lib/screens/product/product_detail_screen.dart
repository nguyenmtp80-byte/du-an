import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/location_map_sheet.dart';
import '../cart/cart_screen.dart';
import '../chat/chat_screen.dart';
import '../../services/api_client.dart';
import '../../services/chat_api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageController = PageController();
  final _chatApiService = ChatApiService();
  int _currentImageIndex = 0;
  bool _isOpeningChat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductDetail(widget.productId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleAddToCart(Product product) async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final userId = auth.user?.id;

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để mua hàng.')),
      );
      return;
    }

    cart.clearError();
    final success = await cart.addToCart(
      userId: userId,
      productId: product.id,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CartScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(cart.errorMessage ?? 'Không thể thêm vào giỏ hàng')),
    );
  }

  Future<void> _handleChat(Product product) async {
    if (_isOpeningChat) {
      return;
    }

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để chat.')),
      );
      return;
    }

    if (product.seller?.id == userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không thể chat với sản phẩm của mình.')),
      );
      return;
    }

    setState(() => _isOpeningChat = true);

    try {
      final room = await _chatApiService.createOrGetRoom(
        userId: userId,
        productId: product.id,
      );

      if (!mounted) {
        return;
      }

      setState(() => _isOpeningChat = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            roomId: room.id,
            currentUserId: userId,
            partnerName: room.partnerNameFor(userId),
            productName: product.name,
            productImageUrl: product.thumbnailUrl,
            productPrice: product.price,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isOpeningChat = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isOpeningChat = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở chat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final product = productProvider.selectedProduct;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: productProvider.isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : productProvider.detailError != null || product == null
              ? _NotFoundView(
                  message: productProvider.detailError ?? 'Không tìm thấy sản phẩm',
                  onBack: () => Navigator.of(context).pop(),
                )
              : _ProductDetailBody(
                  product: product,
                  isFavorite: productProvider.isFavorite(product.id),
                  onToggleFavorite: () =>
                      productProvider.toggleFavorite(product.id),
                  pageController: _pageController,
                  currentImageIndex: _currentImageIndex,
                  onPageChanged: (index) =>
                      setState(() => _currentImageIndex = index),
                  onAddToCart: () => _handleAddToCart(product),
                  isAddingToCart: context.watch<CartProvider>().isAdding,
                  onChat: () => _handleChat(product),
                  isOpeningChat: _isOpeningChat,
                ),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({
    required this.product,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.pageController,
    required this.currentImageIndex,
    required this.onPageChanged,
    required this.onAddToCart,
    required this.isAddingToCart,
    required this.onChat,
    required this.isOpeningChat,
  });

  final Product product;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final PageController pageController;
  final int currentImageIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onAddToCart;
  final bool isAddingToCart;
  final VoidCallback onChat;
  final bool isOpeningChat;

  @override
  Widget build(BuildContext context) {
    final images = product.images.isEmpty
        ? <ProductImage>[]
        : (List<ProductImage>.from(product.images)
          ..sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0)));

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ImageHeader(
                images: images,
                pageController: pageController,
                currentIndex: currentImageIndex,
                onPageChanged: onPageChanged,
                isFavorite: isFavorite,
                onToggleFavorite: onToggleFavorite,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            SliverToBoxAdapter(child: _ProductInfoSection(product: product)),
            SliverToBoxAdapter(child: _SellerSection(product: product)),
            SliverToBoxAdapter(child: _DescriptionSection(product: product)),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomActionBar(
            product: product,
            onAddToCart: onAddToCart,
            isAddingToCart: isAddingToCart,
            onChat: onChat,
            isOpeningChat: isOpeningChat,
          ),
        ),
      ],
    );
  }
}

class _ImageHeader extends StatelessWidget {
  const _ImageHeader({
    required this.images,
    required this.pageController,
    required this.currentIndex,
    required this.onPageChanged,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onBack,
  });

  final List<ProductImage> images;
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            Container(
              color: AppColors.gray200,
              child: const Icon(Icons.image_outlined, size: 64, color: AppColors.gray400),
            )
          else
            PageView.builder(
              controller: pageController,
              itemCount: images.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                return Image.network(
                  images[index].imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.gray200,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                );
              },
            ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OverlayButton(
                  icon: Icons.chevron_left,
                  onTap: onBack,
                ),
                Row(
                  children: [
                    _OverlayButton(
                      icon: Icons.share_outlined,
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    _OverlayButton(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      iconColor: isFavorite ? AppColors.primary : AppColors.gray900,
                      onTap: onToggleFavorite,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final isActive = index == currentIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 8 : 6,
                    height: isActive ? 8 : 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.gray900,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}

class _ProductInfoSection extends StatelessWidget {
  const _ProductInfoSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatPrice(product.price),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Text(
                    formatProductCondition(product.condition),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  product.categoryName,
                  style: const TextStyle(color: AppColors.gray500, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.isAvailable
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatProductStatus(product.status),
                    style: TextStyle(
                      color: product.isAvailable
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Còn ${product.quantity} sp',
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (product.createdAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Đăng ${formatRelativeDate(product.createdAt)}',
                style: const TextStyle(color: AppColors.gray400, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SellerSection extends StatelessWidget {
  const _SellerSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = product.sellerAvatar;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.gray200,
            backgroundImage:
                avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    product.sellerName.isNotEmpty
                        ? product.sellerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.sellerName.isNotEmpty ? product.sellerName : 'Người bán',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Color(0xFFFACC15)),
                    SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '(24 đánh giá)',
                      style: TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: AppColors.gray50,
              foregroundColor: AppColors.gray700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Xem hồ sơ'),
          ),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.description?.trim().isNotEmpty == true
                ? product.description!.trim()
                : 'Chưa có mô tả cho sản phẩm này.',
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (product.locationName != null &&
              product.locationName!.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.gray50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.gray400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Địa điểm giao dịch',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        product.locationName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (product.hasMapLocation)
                  IconButton(
                    onPressed: () => LocationMapSheet.viewLocation(
                      context,
                      latitude: product.latitude!,
                      longitude: product.longitude!,
                      locationLabel: product.locationName,
                    ),
                    icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                    tooltip: 'Xem bản đồ',
                  ),
              ],
            ),
          ],
          if (product.seller?.phone != null &&
              product.seller!.phone!.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.gray50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_outlined, size: 16, color: AppColors.gray400),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Liên hệ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        product.seller!.phone!,
                        style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.product,
    required this.onAddToCart,
    required this.isAddingToCart,
    required this.onChat,
    required this.isOpeningChat,
  });

  final Product product;
  final VoidCallback onAddToCart;
  final bool isAddingToCart;
  final VoidCallback onChat;
  final bool isOpeningChat;

  @override
  Widget build(BuildContext context) {
    final canBuy = product.isAvailable;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray200.withValues(alpha: 0.8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isOpeningChat ? null : onChat,
              icon: isOpeningChat
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: const Color(0xFFFFF7ED),
                side: const BorderSide(color: Color(0xFFFFEDD5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: canBuy && !isAddingToCart ? onAddToCart : null,
              icon: isAddingToCart
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_outlined),
              label: Text(canBuy ? 'Thêm vào giỏ' : 'Đã bán'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.gray200,
                disabledForegroundColor: AppColors.gray500,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView({
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.gray700, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
