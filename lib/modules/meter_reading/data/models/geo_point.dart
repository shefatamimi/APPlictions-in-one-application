/// # GeoPoint
///
/// Framework-free latitude/longitude pair, so the data layer of the module
/// never has to import the map plugin.
library;

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  bool get isValid => latitude != 0 && longitude != 0;

  @override
  String toString() => '$latitude,$longitude';
}
