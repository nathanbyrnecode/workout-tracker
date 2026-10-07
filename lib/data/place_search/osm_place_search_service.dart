import 'dart:convert';
import 'dart:math';

import 'package:gym_tracker_app/data/place_search/device_location.dart';
import 'package:gym_tracker_app/data/place_search/place_search_service.dart';
import 'package:gym_tracker_app/models/place.dart';
import 'package:http/http.dart' as http;

/// Place search on OpenStreetMap data (`dev/decisions.md` 16).
///
/// - Typed search uses Photon, which is built for search-as-you-type.
///   (Nominatim's usage policy forbids that, so it is not used.)
/// - The nearby list uses Overpass to find gyms, sports centres and parks
///   around the user.
///
/// Everything that is specific to these services is in this file. To use a
/// different source, write another [PlaceSearchService] and return it from
/// `placeSearchServiceProvider`.
class OsmPlaceSearchService implements PlaceSearchService {
  OsmPlaceSearchService({
    required http.Client client,
    required DeviceLocation location,
  })  : _client = client,
        _location = location;

  static final photonSearch = Uri.parse('https://photon.komoot.io/api/');
  static final photonReverse = Uri.parse('https://photon.komoot.io/reverse');
  static final overpass = Uri.parse('https://overpass-api.de/api/interpreter');

  /// How far around the user the nearby list looks.
  static const nearbyRadiusMeters = 3000;

  /// The public services ask clients to identify themselves.
  static const _headers = {
    'User-Agent':
        'FittenUp workout tracker (com.nathanbyrne.workouttrackerapp)',
  };
  static const _timeout = Duration(seconds: 8);

  final http.Client _client;
  final DeviceLocation _location;

  /// The last position found, reused so later searches can show distances.
  LatLng? _position;

  @override
  bool get isAvailable => true;

  @override
  String get attribution => '© OpenStreetMap contributors';

  Future<LatLng?> _knownPosition() async =>
      _position ??= await _location.ifAlreadyAllowed();

  @override
  Future<List<PlaceResult>> search(String query) async {
    final text = query.trim();
    if (text.isEmpty) {
      return const [];
    }
    final position = await _knownPosition();
    final response = await _client
        .get(
          photonSearch.replace(queryParameters: {
            'q': text,
            'limit': '8',
            'lang': 'en',
            // Favours results near the user without excluding others.
            if (position != null) ...{
              'lat': '${position.lat}',
              'lon': '${position.lng}',
            },
          }),
          headers: _headers,
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      return const [];
    }
    return parsePhotonFeatures(
      jsonDecode(utf8.decode(response.bodyBytes)),
      from: position,
    );
  }

  @override
  Future<List<PlaceResult>> nearby() async {
    final position = await _knownPosition();
    if (position == null) {
      return const [];
    }
    final query = '[out:json][timeout:8];'
        'nwr(around:$nearbyRadiusMeters,${position.lat},${position.lng})'
        '[leisure~"^(fitness_centre|sports_centre|park)\$"][name];'
        'out center 40;';
    final response = await _client.post(overpass,
        headers: _headers,
        body: {'data': query}).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      return const [];
    }
    return parseOverpassElements(
      jsonDecode(utf8.decode(response.bodyBytes)),
      from: position,
    );
  }

  @override
  Future<PlaceResult?> currentLocation() async {
    final position = await _location.request();
    if (position == null) {
      return null;
    }
    _position = position;

    // The address is a nicety; the position alone is still worth saving.
    String? address;
    try {
      final response = await _client
          .get(
            photonReverse.replace(queryParameters: {
              'lat': '${position.lat}',
              'lon': '${position.lng}',
              'lang': 'en',
            }),
            headers: _headers,
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final nearest = parsePhotonFeatures(
          jsonDecode(utf8.decode(response.bodyBytes)),
        ).firstOrNull;
        final near = nearest?.place.address ?? nearest?.place.name;
        if (near != null && near.isNotEmpty) {
          address = 'Near $near';
        }
      }
    } catch (_) {
      address = null;
    }

    return PlaceResult(
      Place(
        name: 'Current location',
        address: address,
        lat: position.lat,
        lng: position.lng,
      ),
      distanceMeters: 0,
    );
  }
}

/// Reads a Photon GeoJSON response. Features with no name are skipped. With
/// [from], each result carries its distance; the order is Photon's own, which
/// is by relevance.
List<PlaceResult> parsePhotonFeatures(Object? json, {LatLng? from}) {
  if (json is! Map || json['features'] is! List) {
    return const [];
  }
  final results = <PlaceResult>[];
  for (final feature in json['features'] as List) {
    if (feature is! Map) {
      continue;
    }
    final properties = feature['properties'];
    final coordinates = (feature['geometry'] as Map?)?['coordinates'];
    if (properties is! Map) {
      continue;
    }
    final address = _joinAddress(
      street: properties['street'] as String?,
      houseNumber: properties['housenumber'] as String?,
      locality: (properties['city'] ??
          properties['town'] ??
          properties['village'] ??
          properties['county']) as String?,
      postcode: properties['postcode'] as String?,
    );
    // A street address has no name of its own; its address stands in.
    final name = (properties['name'] as String?)?.trim();
    final title = name != null && name.isNotEmpty ? name : address;
    if (title == null) {
      continue;
    }
    double? lat;
    double? lng;
    if (coordinates is List && coordinates.length >= 2) {
      // GeoJSON order is longitude, latitude.
      lng = (coordinates[0] as num?)?.toDouble();
      lat = (coordinates[1] as num?)?.toDouble();
    }
    results.add(
      PlaceResult(
        Place(
          name: title,
          address: title == address ? null : address,
          lat: lat,
          lng: lng,
        ),
        distanceMeters: from != null && lat != null && lng != null
            ? distanceBetween(from, (lat: lat, lng: lng))
            : null,
      ),
    );
  }
  return results;
}

/// Reads an Overpass response into places sorted nearest first. Elements with
/// no name or no position are skipped, and a place mapped more than once
/// (for example as both an outline and a point) appears once.
List<PlaceResult> parseOverpassElements(Object? json, {required LatLng from}) {
  if (json is! Map || json['elements'] is! List) {
    return const [];
  }
  final byName = <String, PlaceResult>{};
  for (final element in json['elements'] as List) {
    if (element is! Map) {
      continue;
    }
    final tags = element['tags'];
    if (tags is! Map) {
      continue;
    }
    final name = (tags['name'] as String?)?.trim();
    // Points carry lat/lon; outlines carry a computed centre.
    final center = element['center'] as Map?;
    final lat = ((element['lat'] ?? center?['lat']) as num?)?.toDouble();
    final lng = ((element['lon'] ?? center?['lon']) as num?)?.toDouble();
    if (name == null || name.isEmpty || lat == null || lng == null) {
      continue;
    }
    final result = PlaceResult(
      Place(
        name: name,
        address: _joinAddress(
          street: tags['addr:street'] as String?,
          houseNumber: tags['addr:housenumber'] as String?,
          locality: (tags['addr:city'] ?? tags['addr:suburb']) as String?,
          postcode: tags['addr:postcode'] as String?,
        ),
        lat: lat,
        lng: lng,
      ),
      distanceMeters: distanceBetween(from, (lat: lat, lng: lng)),
    );
    final existing = byName[name.toLowerCase()];
    if (existing == null || result.distanceMeters! < existing.distanceMeters!) {
      byName[name.toLowerCase()] = result;
    }
  }
  return byName.values.toList()
    ..sort((a, b) => a.distanceMeters!.compareTo(b.distanceMeters!));
}

/// "1 Ducie St, Manchester M1 2JN", from whichever parts are known.
String? _joinAddress({
  String? street,
  String? houseNumber,
  String? locality,
  String? postcode,
}) {
  final line = [
    if (houseNumber != null && houseNumber.isNotEmpty) houseNumber,
    if (street != null && street.isNotEmpty) street,
  ].join(' ');
  final area = [
    if (locality != null && locality.isNotEmpty) locality,
    if (postcode != null && postcode.isNotEmpty) postcode,
  ].join(' ');
  final address = [
    if (line.isNotEmpty) line,
    if (area.isNotEmpty) area,
  ].join(', ');
  return address.isEmpty ? null : address;
}

/// Great-circle distance in metres (haversine).
double distanceBetween(LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  double radians(double degrees) => degrees * pi / 180;
  final dLat = radians(b.lat - a.lat);
  final dLng = radians(b.lng - a.lng);
  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(radians(a.lat)) * cos(radians(b.lat)) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * earthRadius * asin(min(1, sqrt(h)));
}
