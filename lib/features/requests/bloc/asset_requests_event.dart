sealed class AssetRequestsEvent {}

/// Fetch requests for the current user
class MyRequestsFetchRequested extends AssetRequestsEvent {}

/// Fetch all pending requests (admin)
class PendingRequestsFetchRequested extends AssetRequestsEvent {}

/// Create a new request (user submitting)
class AssetRequestCreateRequested extends AssetRequestsEvent {
  final String requestType;
  final String? assetId;
  final Map<String, dynamic> requestData;

  AssetRequestCreateRequested({
    required this.requestType,
    this.assetId,
    required this.requestData,
  });
}

/// Approve a request (admin)
class AssetRequestApproveRequested extends AssetRequestsEvent {
  final String requestId;
  final String? notes;

  AssetRequestApproveRequested({
    required this.requestId,
    this.notes,
  });
}

/// Reject a request (admin)
class AssetRequestRejectRequested extends AssetRequestsEvent {
  final String requestId;
  final String? notes;

  AssetRequestRejectRequested({
    required this.requestId,
    this.notes,
  });
}
