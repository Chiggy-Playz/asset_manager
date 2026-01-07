class AssetAuditLogModel {
  final String id;
  final String? assetId;
  final String? userId;
  final String action;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime createdAt;
  final String? requestId;

  // Populated from joined query
  final String? userName;
  final String? requestNotes;

  const AssetAuditLogModel({
    required this.id,
    this.assetId,
    this.userId,
    required this.action,
    this.oldValues,
    this.newValues,
    required this.createdAt,
    this.requestId,
    this.userName,
    this.requestNotes,
  });

  factory AssetAuditLogModel.fromJson(Map<String, dynamic> json) {
    // Handle nested profile object from joined query
    final profile = json['profiles'] as Map<String, dynamic>?;
    // Handle nested request object from joined query
    final request = json['asset_requests'] as Map<String, dynamic>?;

    return AssetAuditLogModel(
      id: json['id'] as String,
      assetId: json['asset_id'] as String?,
      userId: json['user_id'] as String?,
      action: json['action'] as String,
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      requestId: json['request_id'] as String?,
      userName: profile?['name'] as String?,
      requestNotes: request?['request_notes'] as String?,
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
  bool get hasLinkedRequest => requestId != null;
}
