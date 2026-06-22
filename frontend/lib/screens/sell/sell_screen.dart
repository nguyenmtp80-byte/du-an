import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';

class _SellCategory {
  const _SellCategory({required this.label, required this.value});

  final String label;
  final String value;
}

class _SellCondition {
  const _SellCondition({required this.label, required this.value});

  final String label;
  final String value;
}

const _categories = [
  _SellCategory(label: 'Điện tử', value: 'Điện tử'),
  _SellCategory(label: 'Sách giáo trình', value: 'Sách giáo trình'),
  _SellCategory(label: 'Đồ dùng', value: 'Đồ dùng'),
  _SellCategory(label: 'Dịch vụ', value: 'Dịch vụ'),
];

const _conditions = [
  _SellCondition(label: 'Mới', value: 'NEW'),
  _SellCondition(label: 'Như mới', value: 'LIKE_NEW'),
  _SellCondition(label: 'Đã dùng', value: 'USED'),
];

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCategory = _categories.first.value;
  String? _selectedCondition;
  int _quantity = 1;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = context.read<AuthProvider>().user?.phone;
      if (phone != null && phone.trim().isNotEmpty) {
        _phoneController.text = phone.trim();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập giá bán';
    }

    final price = double.tryParse(value.trim().replaceAll('.', ''));
    if (price == null || price <= 0) {
      return 'Giá bán phải lớn hơn 0';
    }

    return null;
  }

  String? _validateCondition() {
    if (_selectedCondition == null) {
      return 'Vui lòng chọn tình trạng sản phẩm';
    }

    return null;
  }

  void _changeQuantity(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(1, 999);
    });
  }

  Future<void> _handlePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final conditionError = _validateCondition();
    if (conditionError != null) {
      _showMessage(conditionError);
      return;
    }

    setState(() => _isUploading = true);

    // BE chưa có POST /api/products — mock giống React reference.
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (!mounted) {
      return;
    }

    setState(() => _isUploading = false);
    Navigator.of(context).pop();
    _showMessage('Đăng sản phẩm thành công!');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.gray900,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Đăng bán sản phẩm',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  const _SectionLabel('Hình ảnh'),
                  const SizedBox(height: 12),
                  const _PhotoUploadRow(),
                  const SizedBox(height: 24),
                  _FormCard(
                    children: [
                      _SellTextField(
                        label: 'Tên sản phẩm',
                        controller: _nameController,
                        hintText: 'Bạn đang bán gì?',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên sản phẩm';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SellDropdownField(
                              label: 'Danh mục',
                              value: _selectedCategory,
                              items: _categories
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category.value,
                                      child: Text(category.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => _selectedCategory = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionLabel('Số lượng'),
                                const SizedBox(height: 8),
                                _QuantitySelector(
                                  quantity: _quantity,
                                  onDecrease: () => _changeQuantity(-1),
                                  onIncrease: () => _changeQuantity(1),
                                  compact: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SellTextField(
                        label: 'Giá (đ)',
                        controller: _priceController,
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        priceStyle: true,
                        validator: _validatePrice,
                      ),
                      const SizedBox(height: 16),
                      const _SectionLabel('Tình trạng'),
                      const SizedBox(height: 8),
                      _ConditionSelector(
                        conditions: _conditions,
                        selectedValue: _selectedCondition,
                        onSelected: (value) {
                          setState(() => _selectedCondition = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      _SellTextField(
                        label: 'Mô tả',
                        controller: _descriptionController,
                        hintText:
                            'Mô tả sản phẩm (đặc điểm, khuyết điểm, lý do bán)...',
                        maxLines: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _FormCard(
                    children: [
                      _SellTextField(
                        label: 'Địa điểm giao dịch',
                        controller: _locationController,
                        hintText: 'VD: Thư viện chính',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),
                      _SellTextField(
                        label: 'Số điện thoại liên hệ',
                        controller: _phoneController,
                        hintText: '0123456789',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: Validators.phone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Đăng sản phẩm',
                    isLoading: _isUploading,
                    showArrow: false,
                    onPressed: _isUploading ? null : _handlePost,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.gray500,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

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
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _PhotoUploadRow extends StatelessWidget {
  const _PhotoUploadRow();

  static const _slotSize = 96.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _slotSize + 8,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Material(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng chọn ảnh sẽ kết nối khi BE có API upload.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: _slotSize,
                height: _slotSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_outlined, color: AppColors.primary, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Thêm ảnh',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          for (var i = 0; i < 3; i++) ...[
            Container(
              width: _slotSize,
              height: _slotSize,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.upload_outlined,
                color: AppColors.gray400,
                size: 20,
              ),
            ),
            if (i < 2) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _SellTextField extends StatelessWidget {
  const _SellTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.priceStyle = false,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final IconData? prefixIcon;
  final bool priceStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 14,
            color: priceStyle ? AppColors.primary : AppColors.gray900,
            fontWeight: priceStyle ? FontWeight.bold : FontWeight.normal,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
            filled: true,
            fillColor: AppColors.gray50,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: AppColors.gray400, size: 18),
            contentPadding: EdgeInsets.symmetric(
              horizontal: prefixIcon == null ? 16 : 12,
              vertical: maxLines > 1 ? 14 : 12,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _SellDropdownField extends StatelessWidget {
  const _SellDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.gray50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: AppColors.gray900),
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.gray400),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          _QuantityButton(
            icon: Icons.remove,
            onPressed: quantity > 1 ? onDecrease : null,
          ),
          Expanded(
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add,
            onPressed: quantity < 999 ? onIncrease : null,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null ? AppColors.gray400 : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ConditionSelector extends StatelessWidget {
  const _ConditionSelector({
    required this.conditions,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<_SellCondition> conditions;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: conditions.map((condition) {
        final isSelected = selectedValue == condition.value;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: condition == conditions.last ? 0 : 8,
            ),
            child: InkWell(
              onTap: () => onSelected(condition.value),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.gray200,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  condition.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.gray500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
