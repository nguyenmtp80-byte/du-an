import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../repositories/product_repository.dart';
import '../../core/constants/app_strings.dart';
import '../../services/api_client.dart';
import '../../core/themes/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/location_map_sheet.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';

part 'widgets/sell_form_widgets.dart';

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

