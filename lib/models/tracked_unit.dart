
import 'dart:ui';

class TrackedUnitTrailPoint {
  final Offset position;
  final DateTime timestamp;
  TrackedUnitTrailPoint(this.position, this.timestamp);
}

class TrackedUnit {
  final String id;           // Door de app gegenereerde unieke ID (UUID)
  final String iconType;     // Bijv: 'tank', 'fighter', 'spaa'
  final Color color;         // Kleur uit de JSON (#fa0000 etc.)

  Offset position;           // Huidige (x, y) op de kaart (0.0 - 1.0)
  Offset? lastPosition;      // Vorige positie (voor berekenen heading)
  double heading;            // De richting waar de romp naartoe wijst
  double turretAngle;        // De richting van de loop (voor de Speler)

  DateTime lastSeen;         // Timestamp van de laatste succesvolle poll
  bool isPlayer;             // Is dit 'icon: Player'?

  bool isDead;               // Soft delete: true als unit dood is
  DateTime? timeOfDeath;     // Tijdstip van overlijden

  // Trail van posities (voor route-visualisatie)
  final List<TrackedUnitTrailPoint> trail;

  TrackedUnit({
    required this.id,
    required this.iconType,
    required this.color,
    required this.position,
    this.lastPosition,
    this.heading = 0.0,
    this.turretAngle = 0.0,
    required this.lastSeen,
    this.isPlayer = false,
    this.isDead = false,
    this.timeOfDeath,
    List<TrackedUnitTrailPoint>? trail,
  }) : trail = trail ?? [];

  // Bereken de bewegingsrichting op basis van verplaatsing
  void updateHeading() {
    if (lastPosition != null && lastPosition != position) {
      heading = (position - lastPosition!).direction;
    }
  }

  // Voeg een trailpunt toe en snoei oude punten
  void addTrailPoint({int maxSeconds = 300}) {
    final now = DateTime.now();
    trail.add(TrackedUnitTrailPoint(position, now));
    trail.removeWhere((p) => now.difference(p.timestamp).inSeconds > maxSeconds);
  }
}
