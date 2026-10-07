import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/data/place_search/device_location.dart';
import 'package:gym_tracker_app/data/place_search/osm_place_search_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A device at a fixed spot in central Manchester.
class FakeDeviceLocation implements DeviceLocation {
  FakeDeviceLocation({this.allowed = false, this.grantOnRequest = true});

  /// Whether the app already has permission.
  bool allowed;

  /// Whether the user says yes when asked.
  final bool grantOnRequest;
  int requests = 0;

  static const LatLng piccadilly = (lat: 53.4774, lng: -2.2309);

  @override
  Future<LatLng?> ifAlreadyAllowed() async => allowed ? piccadilly : null;

  @override
  Future<LatLng?> request() async {
    requests++;
    if (!grantOnRequest) {
      return null;
    }
    allowed = true;
    return piccadilly;
  }
}

// Shaped like real Photon and Overpass responses, trimmed.
const photonResponse = {
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [-2.2262, 53.4751],
      },
      'properties': {
        'osm_key': 'leisure',
        'osm_value': 'park',
        'name': 'Mayfield Park',
        'street': 'Baring Street',
        'city': 'Manchester',
        'postcode': 'M1 2PY',
        'country': 'United Kingdom',
      },
    },
    {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [-2.2331, 53.4808],
      },
      'properties': {
        'osm_key': 'leisure',
        'osm_value': 'fitness_centre',
        'name': 'PureGym',
        'housenumber': '1',
        'street': 'Ducie Street',
        'city': 'Manchester',
        'postcode': 'M1 2JN',
      },
    },
    // A street address has no name of its own.
    {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [-2.24, 53.47],
      },
      'properties': {
        'housenumber': '2',
        'street': 'Oxford Road',
        'city': 'Manchester',
        'postcode': 'M1 5QA',
      },
    },
    // Nothing usable.
    {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [0, 0],
      },
      'properties': {'osm_key': 'place'},
    },
  ],
};

const overpassResponse = {
  'version': 0.6,
  'elements': [
    // An outline: its position is the computed centre.
    {
      'type': 'way',
      'id': 1,
      'center': {'lat': 53.4751, 'lon': -2.2262},
      'tags': {'leisure': 'park', 'name': 'Mayfield Park'},
    },
    {
      'type': 'node',
      'id': 2,
      'lat': 53.4780,
      'lon': -2.2315,
      'tags': {
        'leisure': 'fitness_centre',
        'name': 'PureGym',
        'addr:housenumber': '1',
        'addr:street': 'Ducie Street',
        'addr:city': 'Manchester',
        'addr:postcode': 'M1 2JN',
      },
    },
    // The same park again, mapped as a point further away.
    {
      'type': 'node',
      'id': 3,
      'lat': 53.4700,
      'lon': -2.2262,
      'tags': {'leisure': 'park', 'name': 'Mayfield Park'},
    },
    // No name: not something a user could pick.
    {
      'type': 'node',
      'id': 4,
      'lat': 53.4775,
      'lon': -2.2310,
      'tags': {'leisure': 'park'},
    },
    // No position.
    {
      'type': 'relation',
      'id': 5,
      'tags': {'leisure': 'sports_centre', 'name': 'Nowhere Sports'},
    },
  ],
};

void main() {
  late List<http.Request> requests;
  late http.Response Function(http.Request request) respond;

  OsmPlaceSearchService service(FakeDeviceLocation location) =>
      OsmPlaceSearchService(
        client: MockClient((request) async {
          requests.add(request);
          return respond(request);
        }),
        location: location,
      );

  http.Response json(Object body, [int status = 200]) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  setUp(() {
    requests = [];
    respond = (request) => request.url.host.contains('overpass')
        ? json(overpassResponse)
        : json(photonResponse);
  });

  group('typed search', () {
    test('asks Photon and reads names, addresses and positions', () async {
      final results = await service(FakeDeviceLocation()).search('  mayfield ');

      final request = requests.single;
      expect(request.url.host, 'photon.komoot.io');
      expect(request.url.path, '/api/');
      expect(request.url.queryParameters['q'], 'mayfield');
      expect(request.headers['User-Agent'], contains('FittenUp'));
      // Without a known position there is no bias and no distance.
      expect(request.url.queryParameters.containsKey('lat'), isFalse);

      expect(results.map((result) => result.place.name), [
        'Mayfield Park',
        'PureGym',
        '2 Oxford Road, Manchester M1 5QA',
      ]);
      expect(results[0].place.address, 'Baring Street, Manchester M1 2PY');
      expect(results[0].place.lat, 53.4751);
      expect(results[0].place.lng, -2.2262);
      expect(results[1].place.address, '1 Ducie Street, Manchester M1 2JN');
      // The address was used as the name, so it is not repeated under it.
      expect(results[2].place.address, isNull);
      expect(results.every((result) => result.distanceMeters == null), isTrue);
    });

    test('with a known position, biases the search and gives distances',
        () async {
      final results =
          await service(FakeDeviceLocation(allowed: true)).search('gym');

      final parameters = requests.single.url.queryParameters;
      expect(parameters['lat'], '53.4774');
      expect(parameters['lon'], '-2.2309');
      // Piccadilly to Mayfield Park is a few hundred metres.
      expect(results[0].distanceMeters, inInclusiveRange(350, 500));
      expect(results[1].distanceMeters, inInclusiveRange(350, 500));
    });

    test('an empty query asks nothing', () async {
      expect(await service(FakeDeviceLocation()).search('   '), isEmpty);
      expect(requests, isEmpty);
    });

    test('a server error or malformed body gives no results', () async {
      respond = (_) => json({'message': 'busy'}, 503);
      expect(await service(FakeDeviceLocation()).search('gym'), isEmpty);

      respond = (_) => json(['not', 'geojson']);
      expect(await service(FakeDeviceLocation()).search('gym'), isEmpty);
    });
  });

  group('nearby', () {
    test('without a position it asks nothing and never requests permission',
        () async {
      final location = FakeDeviceLocation();
      expect(await service(location).nearby(), isEmpty);
      expect(requests, isEmpty);
      expect(location.requests, 0);
    });

    test('asks Overpass for gyms, sports centres and parks around the user',
        () async {
      final results = await service(FakeDeviceLocation(allowed: true)).nearby();

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.host, 'overpass-api.de');
      final query = request.bodyFields['data']!;
      expect(query, contains('around:3000,53.4774,-2.2309'));
      expect(query, contains('fitness_centre|sports_centre|park'));

      // Nearest first, unnamed and unplaced elements dropped, and the park
      // listed once at its nearer position.
      expect(results.map((result) => result.place.name), [
        'PureGym',
        'Mayfield Park',
      ]);
      expect(results[0].place.address, '1 Ducie Street, Manchester M1 2JN');
      expect(results[1].place.address, isNull);
      expect(results[1].place.lat, 53.4751);
      expect(
        results[0].distanceMeters!,
        lessThan(results[1].distanceMeters!),
      );
    });

    test('a server error gives no results', () async {
      respond = (_) => json({'remark': 'timeout'}, 504);
      expect(
          await service(FakeDeviceLocation(allowed: true)).nearby(), isEmpty);
    });
  });

  group('use current location', () {
    test('asks for permission and names the place by what is near', () async {
      final location = FakeDeviceLocation();
      final result = await service(location).currentLocation();

      expect(location.requests, 1);
      expect(requests.single.url.path, '/reverse');
      expect(requests.single.url.queryParameters['lat'], '53.4774');
      expect(result?.place.name, 'Current location');
      expect(result?.place.address, 'Near Baring Street, Manchester M1 2PY');
      expect(result?.place.lat, 53.4774);
      expect(result?.place.lng, -2.2309);
    });

    test('a refusal gives nothing and asks no server', () async {
      final location = FakeDeviceLocation(grantOnRequest: false);
      expect(await service(location).currentLocation(), isNull);
      expect(location.requests, 1);
      expect(requests, isEmpty);
    });

    test('still returns the position when the address lookup fails', () async {
      respond = (_) => json({'message': 'busy'}, 503);
      final result = await service(FakeDeviceLocation()).currentLocation();
      expect(result?.place.name, 'Current location');
      expect(result?.place.address, isNull);
      expect(result?.place.lat, 53.4774);
    });

    test('later searches use the position it found', () async {
      final osm = service(FakeDeviceLocation());
      await osm.currentLocation();
      requests.clear();
      final results = await osm.nearby();
      expect(requests.single.url.host, 'overpass-api.de');
      expect(results, isNotEmpty);
    });
  });

  test('distance between two points', () {
    const LatLng london = (lat: 51.5074, lng: -0.1278);
    const LatLng manchester = (lat: 53.4808, lng: -2.2426);
    // About 262 km.
    expect(distanceBetween(london, manchester), closeTo(262000, 3000));
    expect(distanceBetween(london, london), 0);
  });

  test('the service is available and credits its source', () {
    final osm = service(FakeDeviceLocation());
    expect(osm.isAvailable, isTrue);
    expect(osm.attribution, '© OpenStreetMap contributors');
  });
}
