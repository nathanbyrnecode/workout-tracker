import 'package:gym_tracker_app/data/place_search/device_location.dart';
import 'package:gym_tracker_app/data/place_search/osm_place_search_service.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_search_service.g.dart';

/// A place found by a search, with how far away it is when that is known.
class PlaceResult {
  const PlaceResult(this.place, {this.distanceMeters});

  final Place place;
  final double? distanceMeters;
}

/// Finds places for the optional "Place" on a workout. The UI only talks to
/// this interface, so the source can be swapped without touching it
/// (`dev/decisions.md` 16).
abstract interface class PlaceSearchService {
  /// False when there is nothing behind the interface. The Place part of the
  /// location section is hidden then, rather than offering a search that can
  /// never find anything.
  bool get isAvailable;

  /// Credit the source requires to be shown next to its results, or null.
  String? get attribution;

  /// Places matching what the user typed, best first.
  Future<List<PlaceResult>> search(String query);

  /// Places around the user, nearest first. Empty when their position is not
  /// known; this must not ask for location permission.
  Future<List<PlaceResult>> nearby();

  /// Where the user is now, for "Use current location". May ask for location
  /// permission. Null when it cannot be found or permission is refused.
  Future<PlaceResult?> currentLocation();
}

/// No search, and no Place in the UI. For builds or tests that should not
/// reach any place service.
class UnavailablePlaceSearchService implements PlaceSearchService {
  const UnavailablePlaceSearchService();

  @override
  bool get isAvailable => false;

  @override
  String? get attribution => null;

  @override
  Future<List<PlaceResult>> search(String query) async => const [];

  @override
  Future<List<PlaceResult>> nearby() async => const [];

  @override
  Future<PlaceResult?> currentLocation() async => null;
}

/// The place search the app uses. Change the source here.
@Riverpod(keepAlive: true)
PlaceSearchService placeSearchService(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OsmPlaceSearchService(
    client: client,
    location: const GeolocatorDeviceLocation(),
  );
}
