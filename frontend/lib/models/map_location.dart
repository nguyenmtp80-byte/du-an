class MapLocation {
  const MapLocation({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  final double latitude;
  final double longitude;
  final String? label;

  bool get hasCoordinates => latitude != 0 || longitude != 0;
}
