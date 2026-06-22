import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';

class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({super.key});

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  String? _selectedStatus;
  late String _selectedCategory;

  static const _categoryOptions = [
    'Tất cả',
    'Điện tử',
    'Sách giáo trình',
    'Đồ dùng',
    'Dịch vụ',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    _selectedStatus = provider.statusFilter;
    _selectedCategory = _displayCategory(provider.activeCategory);
    _minPriceController = TextEditingController(
      text: provider.minPrice?.round().toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: provider.maxPrice?.round().toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  String _displayCategory(String category) {
    if (category == 'All') {
      return 'Tất cả';
    }
    return category;
  }

  String _providerCategory(String category) {
    if (category == 'Tất cả') {
      return 'All';
    }
    return category;
  }

  double? _parsePrice(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return double.tryParse(trimmed.replaceAll('.', ''));
  }

  Future<void> _applyFilters() async {
    final provider = context.read<ProductProvider>();
    provider.setActiveCategory(_providerCategory(_selectedCategory));
    provider.setStatusFilter(_selectedStatus);
    provider.setPriceRange(
      minPrice: _parsePrice(_minPriceController.text),
      maxPrice: _parsePrice(_maxPriceController.text),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    await provider.loadProducts();
  }

  Future<void> _resetFilters() async {
    final provider = context.read<ProductProvider>();
    provider.clearFilters();

    setState(() {
      _selectedStatus = null;
      _selectedCategory = 'Tất cả';
      _minPriceController.clear();
      _maxPriceController.clear();
    });

    await provider.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
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
          const SizedBox(height: 20),
          const Text(
            'Bộ lọc',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Danh mục'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categoryOptions.map((category) {
              return _FilterChip(
                label: category,
                selected: _selectedCategory == category,
                onTap: () => setState(() => _selectedCategory = category),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Trạng thái'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'Tất cả',
                selected: _selectedStatus == null,
                onTap: () => setState(() => _selectedStatus = null),
              ),
              _FilterChip(
                label: 'Còn hàng',
                selected: _selectedStatus == 'available',
                onTap: () => setState(() => _selectedStatus = 'available'),
              ),
              _FilterChip(
                label: 'Hết hàng',
                selected: _selectedStatus == 'sold',
                onTap: () => setState(() => _selectedStatus = 'sold'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Khoảng giá (đ)'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PriceField(
                  controller: _minPriceController,
                  hintText: 'Tối thiểu',
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '—',
                  style: TextStyle(color: AppColors.gray400, fontSize: 16),
                ),
              ),
              Expanded(
                child: _PriceField(
                  controller: _maxPriceController,
                  hintText: 'Tối đa',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.gray200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Xóa lọc',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _applyFilters,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Áp dụng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.gray700,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.gray200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.gray700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14, color: AppColors.gray900),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
