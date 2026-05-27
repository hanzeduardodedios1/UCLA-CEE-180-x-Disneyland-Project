class HotelRow {
  const HotelRow({
    required this.hotel,
    required this.address,
    required this.nightlyRate,
    required this.drivingCost,
    required this.walkMins,
    this.transitMins,
    required this.transitSavedMins,
  });

  final String hotel;
  final String address;
  final int nightlyRate;
  final int drivingCost;
  final double walkMins;
  final double? transitMins;
  final double transitSavedMins;

  factory HotelRow.fromJson(Map<String, dynamic> json) {
    return HotelRow(
      hotel: json['hotel'] as String,
      address: json['address'] as String,
      nightlyRate: (json['nightly_rate'] as num).round(),
      drivingCost: (json['drivingcost'] as num).round(),
      walkMins: (json['walk_mins'] as num).toDouble(),
      transitMins: json['transit_mins'] == null
          ? null
          : (json['transit_mins'] as num).toDouble(),
      transitSavedMins: (json['transit_saved_mins'] as num).toDouble(),
    );
  }
}
