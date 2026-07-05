import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../repositories/product_repository.dart';
import '../../core/constants/app_strings.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/location_map_sheet.dart';
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

const _maxProductImages = 4;

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productRepository = ProductRepository();
  final _imagePicker = ImagePicker();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCategory = _categories.first.value;
  String? _selectedCondition;
  int _quantity = 1;
  bool _isUploading = false;
  final List<XFile> _pickedImages = [];
  final Map<String, Uint8List> _imageBytes = {};
  double? _latitude;
  double? _longitude;

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

  Future<void> _pickImages() async {
    if (_pickedImages.length >= _maxProductImages) {
      _showMessage('Chỉ được thêm tối đa $_maxProductImages ảnh.');
      return;
    }

    try {
      final picked = await _imagePicker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) {
        return;
      }

      for (final image in picked) {
        if (_pickedImages.length >= _maxProductImages) {
          break;
        }

        final bytes = await image.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          _showMessage('Ảnh "${image.name}" quá lớn (tối đa 2MB/ảnh).');
          continue;
        }

        setState(() {
          _pickedImages.add(image);
          _imageBytes[image.path] = bytes;
        });
      }
    } catch (_) {
      _showMessage('Không thể chọn ảnh. Vui lòng thử lại.');
    }
  }

  void _removeImage(int index) {
    setState(() {
      final removed = _pickedImages.removeAt(index);
      _imageBytes.remove(removed.path);
    });
  }

  Future<void> _pickLocationOnMap() async {
    final picked = await LocationMapSheet.pickLocation(
      context,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
      locationLabel: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _latitude = picked.latitude;
      _longitude = picked.longitude;
    });

    _showMessage('Đã chọn vị trí trên bản đồ.');
  }

  Future<List<String>> _uploadImages() async {
    if (_pickedImages.isEmpty) {
      return [];
    }

    final bytesList = <Uint8List>[];
    for (final image in _pickedImages) {
      bytesList.add(await image.readAsBytes());
    }

    return _productRepository.uploadProductImages(bytesList);
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

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      _showMessage('Vui lòng đăng nhập để đăng bán.');
      return;
    }

    final priceText = _priceController.text.trim().replaceAll('.', '');
    final price = int.tryParse(priceText);
    if (price == null || price <= 0) {
      _showMessage('Giá bán phải lớn hơn 0');
      return;
    }

    setState(() => _isUploading = true);

    try {
      var uploadedUrls = <String>[];
      if (_pickedImages.isNotEmpty) {
        uploadedUrls = await _uploadImages();
        if (!mounted) return;
      }

      await _productRepository.createProduct(
        userId: userId,
        title: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: _selectedCategory,
        condition: _selectedCondition!,
        quantity: _quantity,
        locationName: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        imageUrls: uploadedUrls.isNotEmpty ? uploadedUrls : null,
      );

      if (!mounted) {
        return;
      }

      await context.read<ProductProvider>().refreshProducts();
      if (!mounted) {
        return;
      }

      setState(() => _isUploading = false);
      Navigator.of(context).pop();
      _showMessage('Đăng sản phẩm thành công!');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isUploading = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isUploading = false);
      _showMessage('Không thể đăng sản phẩm. Vui lòng thử lại.');
    }
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
            title: AppStrings.sellProduct,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  const _SectionLabel('Hình ảnh'),
                  const SizedBox(height: 4),
                  const Text(
                    'Chọn ảnh sản phẩm (tối đa 4 ảnh, mỗi ảnh tối đa 2MB).',
                    style: TextStyle(fontSize: 12, color: AppColors.gray500, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  _PhotoUploadRow(
                    images: _pickedImages,
                    imageBytes: _imageBytes,
                    maxImages: _maxProductImages,
                    onAdd: _pickImages,
                    onRemove: _removeImage,
                  ),
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
                          if (value.trim().length > 255) {
                            return 'Tên sản phẩm tối đa 255 ký tự';
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
                      _SellLocationField(
                        controller: _locationController,
                        hasPinnedLocation: _latitude != null && _longitude != null,
                        onOpenMap: _pickLocationOnMap,
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
                    label: AppStrings.postProduct,
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
  const _PhotoUploadRow({
    required this.images,
    required this.imageBytes,
    required this.maxImages,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> images;
  final Map<String, Uint8List> imageBytes;
  final int maxImages;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  static const _slotSize = 96.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _slotSize + 8,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (images.length < maxImages)
            Material(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onAdd,
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
          for (var i = 0; i < images.length; i++) ...[
            if (i == 0 && images.length < maxImages) const SizedBox(width: 12),
            _PickedImageTile(
              bytes: imageBytes[images[i].path],
              onRemove: () => onRemove(i),
            ),
            if (i < images.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _PickedImageTile extends StatelessWidget {
  const _PickedImageTile({
    required this.bytes,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: _PhotoUploadRow._slotSize,
            height: _PhotoUploadRow._slotSize,
            child: bytes == null
                ? Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.image_outlined, color: AppColors.gray400),
                  )
                : Image.memory(
                    bytes!,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: AppColors.gray900,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 22,
                height: 22,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SellLocationField extends StatelessWidget {
  const _SellLocationField({
    required this.controller,
    required this.hasPinnedLocation,
    required this.onOpenMap,
  });

  final TextEditingController controller;
  final bool hasPinnedLocation;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Địa điểm giao dịch'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                style: const TextStyle(fontSize: 14, color: AppColors.gray900),
                decoration: InputDecoration(
                  hintText: 'VD: Thư viện chính',
                  hintStyle:
                      const TextStyle(color: AppColors.gray400, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.gray50,
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.gray400,
                    size: 18,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
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
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: hasPinnedLocation ? AppColors.primaryLight : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onOpenMap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasPinnedLocation
                          ? AppColors.primary
                          : const Color(0xFFF3F4F6),
                    ),
                  ),
                  child: Icon(
                    Icons.map_outlined,
                    color: hasPinnedLocation
                        ? AppColors.primary
                        : AppColors.gray500,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasPinnedLocation)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Đã ghim vị trí trên bản đồ',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
      ],
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
