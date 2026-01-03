class ProfileModel {
  final String id;
  final String name;
  final String role;
  final DateTime createdAt;
  final bool isActive;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.isActive,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool get isAdmin => role == 'admin';
}
