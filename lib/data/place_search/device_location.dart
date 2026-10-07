import 'package:geolocator/geolocator.dart';

typedef LatLng = ({double lat, double lng});

/// Where the device is. Kept behind an interface so place search can be
/// tested without the platform's location services.
abstract interface class DeviceLocation {
  /// The position if the app may already read it. Never asks for permission,
  /// so it is safe to call without the user having asked for anything.
  Future<LatLng?> ifAlreadyAllowed();

  /// The position, asking for permission first if needed. Call this only when
  /// the user taps "Use current location". Null when permission is refused,
  /// location is switched off or no position can be found.
  Future<LatLng?> request();
}

class GeolocatorDeviceLocation implements DeviceLocation {
  const GeolocatorDeviceLocation();

  static bool _granted(LocationPermission permission) =>
      permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;

  @override
  Future<LatLng?> ifAlreadyAllowed() async {
    try {
      if (!_granted(await Geolocator.checkPermission())) {
        return null;
      }
      final position = await Geolocator.getLastKnownPosition();
      return position == null
          ? null
          : (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LatLng?> request() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!_granted(permission)) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          // Enough to find the nearest gym, and quicker than a precise fix.
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return null;
    }
  }
}
