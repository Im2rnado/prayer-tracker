class RulesModel {
  final String guardianId;
  final int onTimePoints;
  final int latePoints;
  final int onTimeJamaahPoints;
  final int lateJamaahPoints;

  // Custom Waqt al-Fadila buffers in minutes (null means use the smart default window)
  final int? fajrBuffer;
  final int? dhuhrBuffer;
  final int? asrBuffer;
  final int? maghribBuffer;
  final int? ishaBuffer;

  RulesModel({
    required this.guardianId,
    this.onTimePoints = 10,
    this.latePoints = 2,
    this.onTimeJamaahPoints = 20,
    this.lateJamaahPoints = 5,
    this.fajrBuffer,
    this.dhuhrBuffer,
    this.asrBuffer,
    this.maghribBuffer,
    this.ishaBuffer,
  });

  factory RulesModel.fromJson(Map<String, dynamic> json) {
    return RulesModel(
      guardianId: json['guardianId'] ?? '',
      onTimePoints: json['onTimePoints'] ?? 10,
      latePoints: json['latePoints'] ?? 2,
      onTimeJamaahPoints: json['onTimeJamaahPoints'] ?? 20,
      lateJamaahPoints: json['lateJamaahPoints'] ?? 5,
      fajrBuffer: json['fajrBuffer'],
      dhuhrBuffer: json['dhuhrBuffer'],
      asrBuffer: json['asrBuffer'],
      maghribBuffer: json['maghribBuffer'],
      ishaBuffer: json['ishaBuffer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guardianId': guardianId,
      'onTimePoints': onTimePoints,
      'latePoints': latePoints,
      'onTimeJamaahPoints': onTimeJamaahPoints,
      'lateJamaahPoints': lateJamaahPoints,
      'fajrBuffer': fajrBuffer,
      'dhuhrBuffer': dhuhrBuffer,
      'asrBuffer': asrBuffer,
      'maghribBuffer': maghribBuffer,
      'ishaBuffer': ishaBuffer,
    };
  }
}
