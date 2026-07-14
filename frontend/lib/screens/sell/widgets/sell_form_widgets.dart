part of '../sell_screen.dart';

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
