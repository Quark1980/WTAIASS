class GameState {
  final double latitude;
  final double longitude;
  final double altitude;
  final int deaths;

  GameState({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.deaths,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      altitude: (json['altitude'] ?? 0).toDouble(),
      deaths: json['deaths'] ?? 0,
    );
  }
}
