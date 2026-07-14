import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/map_location.dart';
import '../core/themes/app_theme.dart';
import '../utils/map_constants.dart';

class LocationMapSheet extends StatefulWidget {
  const LocationMapSheet({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.title = 'Chọn vị trí',
    this.pickMode = true,
    this.locationLabel,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final String title;
  final bool pickMode;
  final String? locationLabel;

  static Future<MapLocation?> pickLocation(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    String? locationLabel,
  }) {
    return showModalBottomSheet<MapLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationMapSheet(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
        locationLabel: locationLabel,
        pickMode: true,
        title: 'Chọn vị trí giao dịch',
      ),
    );
  }

  static Future<void> viewLocation(
    BuildContext context, {
    required double latitude,
    required double longitude,
    String? locationLabel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationMapSheet(
        initialLatitude: latitude,
        initialLongitude: longitude,
        locationLabel: locationLabel,
        pickMode: false,
        title: 'Vị trí giao dịch',
      ),
    );
  }

  @override
  State<LocationMapSheet> createState() => _LocationMapSheetState();
}

class _LocationMapSheetState extends State<LocationMapSheet> {
  late final MapController _mapController;
  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPoint = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedPoint != null) {
        _focusOnPoint(_selectedPoint!);
      }
    });
  }

  void _focusOnPoint(LatLng point) {
    _mapController.move(point, MapConstants.detailZoom);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!widget.pickMode) {
      setState(() => _selectedPoint = point);
      _focusOnPoint(point);
      return;
    }

    setState(() => _selectedPoint = point);
    _focusOnPoint(point);
  }

  void _onMarkerTap() {
    final point = _selectedPoint;
    if (point == null) {
      return;
    }

    _focusOnPoint(point);
  }

  void _confirmSelection() {
    final point = _selectedPoint;
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn vị trí trên bản đồ.')),
      );
      return;
    }

    Navigator.of(context).pop(
      MapLocation(
        latitude: point.latitude,
        longitude: point.longitude,
        label: widget.locationLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapHeight = MediaQuery.sizeOf(context).height * 0.72;
    final center = _selectedPoint ?? MapConstants.thuDucCenter;
    final initialZoom =
        _selectedPoint != null && !widget.pickMode
            ? MapConstants.detailZoom
            : MapConstants.defaultZoom;

    return Container(
      height: mapHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.pickMode
                            ? 'Chạm bản đồ để ghim vị trí (Thủ Đức, TP.HCM)'
                            : 'Chạm ghim hoặc bản đồ để phóng to vị trí',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                      if (widget.locationLabel != null &&
                          widget.locationLabel!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.locationLabel!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: initialZoom,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.student_marketplace',
                    ),
                    if (_selectedPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint!,
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: _onMarkerTap,
                              child: const Icon(
                                Icons.location_pin,
                                color: AppColors.primary,
                                size: 44,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.pickMode)
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.paddingOf(context).bottom + 16,
              ),
              child: FilledButton(
                onPressed: _confirmSelection,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Xác nhận vị trí',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
        ],
      ),
    );
  }
}

class ViewLocationMapButton extends StatelessWidget {
  const ViewLocationMapButton({
    super.key,
    required this.latitude,
    required this.longitude,
    this.locationLabel,
    this.compact = false,
  });

  final double latitude;
  final double longitude;
  final String? locationLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: () => LocationMapSheet.viewLocation(
          context,
          latitude: latitude,
          longitude: longitude,
          locationLabel: locationLabel,
        ),
        icon: const Icon(Icons.map_outlined, color: AppColors.primary),
        tooltip: 'Xem bản đồ',
      );
    }

    return OutlinedButton.icon(
      onPressed: () => LocationMapSheet.viewLocation(
        context,
        latitude: latitude,
        longitude: longitude,
        locationLabel: locationLabel,
      ),
      icon: const Icon(Icons.map_outlined, size: 18),
      label: const Text('Xem bản đồ'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primarySoft),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
