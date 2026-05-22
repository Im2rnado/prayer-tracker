enum PrayerStatus { onTime, late, onTimeJamaah, lateJamaah }

class PrayerLogModel {
  final String id;
  final String childId;
  final String prayerName; // Fajr, Dhuhr, Asr, Maghrib, Isha
  final String method; // Single, Jama'ah
  final DateTime timestamp;
  final PrayerStatus status;
  final int pointsEarned;

  PrayerLogModel({
    required this.id,
    required this.childId,
    required this.prayerName,
    required this.method,
    required this.timestamp,
    required this.status,
    required this.pointsEarned,
  });

  factory PrayerLogModel.fromJson(Map<String, dynamic> json) {
    return PrayerLogModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      prayerName: json['prayerName'] ?? '',
      method: json['method'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      status: PrayerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PrayerStatus.late,
      ),
      pointsEarned: json['pointsEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'prayerName': prayerName,
      'method': method,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'pointsEarned': pointsEarned,
    };
  }
}
