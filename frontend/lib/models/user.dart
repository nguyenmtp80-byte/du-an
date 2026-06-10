class User {
  const User({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.studentId,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? studentId;
  final DateTime? createdAt;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : email;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      studentId: json['studentId'] as String? ?? json['student_id'] as String?,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'studentId': studentId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
