import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../product/product_filter_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().initialize();
      _loadCart();
      _loadUnreadNotifications();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProductFilterSheet(),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.notifications,
      arguments: true,
    );

    if (!mounted) {
      return;
    }

    await _loadUnreadNotifications();
  }

  void _openProductDetail(String productId) {
    Navigator.of(context).pushNamed(
      AppRoutes.productDetail,
      arguments: {AppRoutes.productIdArg: productId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final hasUnread = context.watch<NotificationProvider>().hasUnread;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        onRefresh: () async {
          await productProvider.refreshProducts();
          await _loadCart();
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(
                searchController: _searchController,
                onFilterTap: _openFilterSheet,
                onNotificationTap: _openNotifications,
                onSearchChanged: productProvider.setSearchQuery,
                showNotificationBadge: hasUnread,
              ),
            ),
            if (productProvider.isUsingDetailFallback)
              const SliverToBoxAdapter(child: _FallbackBanner()),
            SliverToBoxAdapter(
              child: _CategoryChips(
                categories: productProvider.categories,
                activeCategory: productProvider.activeCategory,
                onCategorySelected: productProvider.setActiveCategory,
              ),
            ),
            const SliverToBoxAdapter(child: _PromoBanner()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.screenPadding,
                AppSizes.screenPadding,
                AppSizes.screenPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  AppStrings.suggestedForYou,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                ),
              ),
            ),
            if (productProvider.isLoadingList)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingStateView(),
              )
            else if (productProvider.listError != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorStateView(
                  message: productProvider.listError!,
                  onRetry: productProvider.loadProducts,
                  retryLabel: AppStrings.retry,
                ),
              )
            else if (productProvider.filteredProducts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  title: AppStrings.emptyProductsTitle,
                  subtitle: AppStrings.emptyProductsSubtitle,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  0,
                  AppSizes.screenPadding,
                  120,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: AppSizes.productGridColumns,
                    mainAxisSpacing: AppSizes.gridSpacing,
                    crossAxisSpacing: AppSizes.gridSpacing,
                    childAspectRatio: AppSizes.gridAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = productProvider.filteredProducts[index];

                      return ProductCard(
                        product: product,
                        isFavorite: productProvider.isFavorite(product.id),
                        onToggleFavorite: () =>
                            productProvider.toggleFavorite(product.id),
                        onTap: () => _openProductDetail(product.id),
                      );
                    },
                    childCount: productProvider.filteredProducts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.searchController,
    required this.onFilterTap,
    required this.onNotificationTap,
    required this.onSearchChanged,
    this.showNotificationBadge = false,
  });

  final TextEditingController searchController;
  final VoidCallback onFilterTap;
  final VoidCallback onNotificationTap;
  final ValueChanged<String> onSearchChanged;
  final bool showNotificationBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSizes.headerRadius),
          bottomRight: Radius.circular(AppSizes.headerRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33F97316),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        MediaQuery.paddingOf(context).top + 16,
        AppSizes.screenPadding,
        16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.campusMarket,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.campusLocation,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _HeaderIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: onNotificationTap,
                    showBadge: showNotificationBadge,
                  ),
                  const SizedBox(width: 8),
                  _HeaderIconButton(
                    icon: Icons.tune,
                    onTap: onFilterTap,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: AppStrings.searchHint,
              hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              if (showBadge)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
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

class _FallbackBanner extends StatelessWidget {
  const _FallbackBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        16,
        AppSizes.screenPadding,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: const Text(
        'GET /api/products đang lỗi phía BE. '
        'Đang hiển thị sản phẩm mẫu (prod-1, prod-2, prod-3) từ API chi tiết.',
        style: TextStyle(fontSize: 12, color: AppColors.gray700, height: 1.4),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.activeCategory,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final String activeCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          16,
          AppSizes.screenPadding,
          0,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = category == activeCategory;
          final label =
              category == 'All' ? AppStrings.allCategories : category;

          return FilterChip(
            label: Text(label),
            selected: isActive,
            onSelected: (_) => onCategorySelected(category),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isActive ? Colors.white : AppColors.gray700,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            backgroundColor: Colors.white,
            selectedColor: AppColors.primary,
            side: BorderSide(
              color: isActive ? AppColors.primary : AppColors.gray200,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.chipRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        16,
        AppSizes.screenPadding,
        0,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFB923C), AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Finals Week Sale!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giảm đến 50% sách và tài liệu ôn thi',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.chipRadius),
                  ),
                  child: const Text(
                    'Mua ngay',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: -8,
            bottom: -12,
            child: Text(
              '📚',
              style: TextStyle(fontSize: 72),
            ),
          ),
        ],
      ),
    );
  }
}
