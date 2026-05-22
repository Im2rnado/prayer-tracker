enum UserRole { child, guardian }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final int totalPoints;
  final String? inviteCode;
  final List<String> linkedGuardianIds; // For child
  final List<String> linkedChildIds; // For guardian

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.totalPoints = 0,
    this.inviteCode,
    this.linkedGuardianIds = const [],
    this.linkedChildIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] == 'guardian' ? UserRole.guardian : UserRole.child,
      totalPoints: json['totalPoints'] ?? 0,
      inviteCode: json['inviteCode'],
      linkedGuardianIds: List<String>.from(json['linkedGuardianIds'] ?? []),
      linkedChildIds: List<String>.from(json['linkedChildIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
      'totalPoints': totalPoints,
      'inviteCode': inviteCode,
      'linkedGuardianIds': linkedGuardianIds,
      'linkedChildIds': linkedChildIds,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    int? totalPoints,
    String? inviteCode,
    List<String>? linkedGuardianIds,
    List<String>? linkedChildIds,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      totalPoints: totalPoints ?? this.totalPoints,
      inviteCode: inviteCode ?? this.inviteCode,
      linkedGuardianIds: linkedGuardianIds ?? this.linkedGuardianIds,
      linkedChildIds: linkedChildIds ?? this.linkedChildIds,
    );
  }
}
