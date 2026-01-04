enum AssetRequestType { create, update, delete, transfer }

enum AssetRequestStatus { pending, approved, rejected }

class AssetRequestModel {
  final String id;
  final String? assetId;
  final AssetRequestType requestType;
  final Map<String, dynamic> requestData;
  final Map<String, dynamic>? currentData;
  final String? requestedBy;
  final DateTime requestedAt;
  final AssetRequestStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;

  // Populated from joined query
  final String? requesterName;
  final String? reviewerName;
  final String? assetTagId;

  const AssetRequestModel({
    required this.id,
    this.assetId,
    required this.requestType,
    required this.requestData,
    required this.currentData,
    this.requestedBy,
    required this.requestedAt,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    this.requesterName,
    this.reviewerName,
    this.assetTagId,
  });

  factory AssetRequestModel.fromJson(Map<String, dynamic> json) {
    // Handle nested profiles for requester
    final requester = json['requester'] as Map<String, dynamic>?;
    final reviewer = json['reviewer'] as Map<String, dynamic>?;
    final asset = json['assets'] as Map<String, dynamic>?;

    return AssetRequestModel(
      id: json['id'] as String,
      assetId: json['asset_id'] as String?,
      requestType: _parseRequestType(json['request_type'] as String),
      requestData: json['request_data'] as Map<String, dynamic>? ?? {},
      currentData: json['current_data'] as Map<String, dynamic>?,
      requestedBy: json['requested_by'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      status: _parseStatus(json['status'] as String),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewNotes: json['review_notes'] as String?,
      requesterName: requester?['name'] as String?,
      reviewerName: reviewer?['name'] as String?,
      assetTagId: asset?['tag_id'] as String?,
    );
  }

  static AssetRequestType _parseRequestType(String type) {
    return switch (type) {
      'create' => AssetRequestType.create,
      'update' => AssetRequestType.update,
      'delete' => AssetRequestType.delete,
      'transfer' => AssetRequestType.transfer,
      _ => AssetRequestType.update,
    };
  }

  static AssetRequestStatus _parseStatus(String status) {
    return switch (status) {
      'pending' => AssetRequestStatus.pending,
      'approved' => AssetRequestStatus.approved,
      'rejected' => AssetRequestStatus.rejected,
      _ => AssetRequestStatus.pending,
    };
  }

  String get requestTypeString {
    return switch (requestType) {
      AssetRequestType.create => 'create',
      AssetRequestType.update => 'update',
      AssetRequestType.delete => 'delete',
      AssetRequestType.transfer => 'transfer',
    };
  }

  String get statusString {
    return switch (status) {
      AssetRequestStatus.pending => 'pending',
      AssetRequestStatus.approved => 'approved',
      AssetRequestStatus.rejected => 'rejected',
    };
  }

  String get displayType {
    return switch (requestType) {
      AssetRequestType.create => 'Create Asset',
      AssetRequestType.update => 'Update Asset',
      AssetRequestType.delete => 'Delete Asset',
      AssetRequestType.transfer => 'Transfer Asset',
    };
  }

  String get displayStatus {
    return switch (status) {
      AssetRequestStatus.pending => 'Pending',
      AssetRequestStatus.approved => 'Approved',
      AssetRequestStatus.rejected => 'Rejected',
    };
  }

  bool get isPending => status == AssetRequestStatus.pending;
  bool get isApproved => status == AssetRequestStatus.approved;
  bool get isRejected => status == AssetRequestStatus.rejected;

  bool get isCreate => requestType == AssetRequestType.create;
  bool get isUpdate => requestType == AssetRequestType.update;
  bool get isDelete => requestType == AssetRequestType.delete;
  bool get isTransfer => requestType == AssetRequestType.transfer;
}
