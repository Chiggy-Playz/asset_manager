class AssetAuditLogModel {
  final String id;
  final String? assetId;
  final String? userId;
  final String action;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime createdAt;

  // Populated from joined query
  final String? userName;

  const AssetAuditLogModel({
    required this.id,
    this.assetId,
    this.userId,
    required this.action,
    this.oldValues,
    this.newValues,
    required this.createdAt,
    this.userName,
  });

  factory AssetAuditLogModel.fromJson(Map<String, dynamic> json) {
    // Handle nested profile object from joined query
    final profile = json['profiles'] as Map<String, dynamic>?;

    return AssetAuditLogModel(
      id: json['id'] as String,
      assetId: json['asset_id'] as String?,
      userId: json['user_id'] as String?,
      action: json['action'] as String,
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: profile?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_id': assetId,
      'user_id': userId,
      'action': action,
      'old_values': oldValues,
      'new_values': newValues,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCreated => action == 'created';
  bool get isUpdated => action == 'updated';
  bool get isDeleted => action == 'deleted';
  bool get isTransferred => action == 'transferred';
}
