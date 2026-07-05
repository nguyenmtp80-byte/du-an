import 'package:latlong2/latlong.dart';

class MapConstants {
  static const double thuDucLat = 10.8700;
  static const double thuDucLng = 106.8030;
  static const double defaultZoom = 14;
  static const double detailZoom = 16.5;

  static LatLng get thuDucCenter => const LatLng(thuDucLat, thuDucLng);
}
