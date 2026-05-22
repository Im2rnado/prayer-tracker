class RewardModel {
  final String id;
  final String guardianId;
  final String title;
  final int pointCost;
  final String? imageUrl;
  final String? iconEmoji; // e.g. "🎮", "📱", "🍕"

  RewardModel({
    required this.id,
    required this.guardianId,
    required this.title,
    required this.pointCost,
    this.imageUrl,
    this.iconEmoji,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] ?? '',
      guardianId: json['guardianId'] ?? '',
      title: json['title'] ?? '',
      pointCost: json['pointCost'] ?? 0,
      imageUrl: json['imageUrl'],
      iconEmoji: json['iconEmoji'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guardianId': guardianId,
      'title': title,
      'pointCost': pointCost,
      'imageUrl': imageUrl,
      'iconEmoji': iconEmoji,
    };
  }

  RewardModel copyWith({
    String? id,
    String? guardianId,
    String? title,
    int? pointCost,
    String? imageUrl,
    String? iconEmoji,
  }) {
    return RewardModel(
      id: id ?? this.id,
      guardianId: guardianId ?? this.guardianId,
      title: title ?? this.title,
      pointCost: pointCost ?? this.pointCost,
      imageUrl: imageUrl ?? this.imageUrl,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }
}
