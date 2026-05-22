class RulesModel {
  final String guardianId;
  final int onTimePoints;
  final int latePoints;
  final int onTimeJamaahPoints;
  final int lateJamaahPoints;

  RulesModel({
    required this.guardianId,
    this.onTimePoints = 10,
    this.latePoints = 2,
    this.onTimeJamaahPoints = 20,
    this.lateJamaahPoints = 5,
  });

  factory RulesModel.fromJson(Map<String, dynamic> json) {
    return RulesModel(
      guardianId: json['guardianId'] ?? '',
      onTimePoints: json['onTimePoints'] ?? 10,
      latePoints: json['latePoints'] ?? 2,
      onTimeJamaahPoints: json['onTimeJamaahPoints'] ?? 20,
      lateJamaahPoints: json['lateJamaahPoints'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guardianId': guardianId,
      'onTimePoints': onTimePoints,
      'latePoints': latePoints,
      'onTimeJamaahPoints': onTimeJamaahPoints,
      'lateJamaahPoints': lateJamaahPoints,
    };
  }
}
