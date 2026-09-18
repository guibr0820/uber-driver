import 'package:geocoding/geocoding.dart';

class GeocodingService {
  static final Map<String, Map<String, String>> _cache = {};

  static Future<Map<String, String>> getAddressFromLatLng({
    required double lat,
    required double lng,
  }) async {
    _cache.clear();
    final key = "$lat,$lng";

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final place = placemarks.first;

      final result = {
        "cidade": (place.locality?.isNotEmpty == true
            ? place.locality
            : place.subAdministrativeArea) ?? "",

        "rua": place.street ?? "",

        "bairro": (place.subLocality?.isNotEmpty == true
            ? place.subLocality
            : place.subAdministrativeArea) ?? "",
      };

      _cache[key] = result;

      return result;
    } catch (_) {
      return {
        "cidade": "Não encontrado",
        "rua": "",
        "bairro": "",
      };
    }
  }
}