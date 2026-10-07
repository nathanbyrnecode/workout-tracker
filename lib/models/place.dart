class Place {
  const Place({
    required this.name,
    this.address,
    this.lat,
    this.lng,
  });

  final String name;
  final String? address;
  final double? lat;
  final double? lng;
}
