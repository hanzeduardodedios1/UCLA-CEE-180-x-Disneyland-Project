class HotelRoute {
  const HotelRoute({
    required this.hotel,
    required this.origin,
    required this.destination,
    required this.distanceText,
    required this.distanceMeters,
    required this.durationText,
    required this.durationSeconds,
    required this.durationMins,
    required this.polyline,
  });

  final String hotel;
  final String origin;
  final String destination;
  final String distanceText;
  final int distanceMeters;
  final String durationText;
  final int durationSeconds;
  final double durationMins;
  final String polyline;

  factory HotelRoute.fromJson(Map<String, dynamic> json) {
    return HotelRoute(
      hotel: json['hotel'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      distanceText: json['distance_text'] as String,
      distanceMeters: json['distance_meters'] as int,
      durationText: json['duration_text'] as String,
      durationSeconds: json['duration_seconds'] as int,
      durationMins: (json['duration_mins'] as num).toDouble(),
      polyline: json['polyline'] as String,
    );
  }
}
