import '../../../data/models/asset_request_model.dart';

sealed class AssetRequestsState {}

class AssetRequestsInitial extends AssetRequestsState {}

class AssetRequestsLoading extends AssetRequestsState {}

class AssetRequestsLoaded extends AssetRequestsState {
  final List<AssetRequestModel> requests;

  AssetRequestsLoaded(this.requests);

  List<AssetRequestModel> get pendingRequests =>
      requests.where((r) => r.isPending).toList();

  List<AssetRequestModel> get approvedRequests =>
      requests.where((r) => r.isApproved).toList();

  List<AssetRequestModel> get rejectedRequests =>
      requests.where((r) => r.isRejected).toList();
}

class AssetRequestsError extends AssetRequestsState {
  final String message;

  AssetRequestsError(this.message);
}

class AssetRequestActionInProgress extends AssetRequestsState {
  final List<AssetRequestModel> requests;
  final String? actionRequestId;

  AssetRequestActionInProgress(this.requests, {this.actionRequestId});
}

class AssetRequestActionSuccess extends AssetRequestsState {
  final List<AssetRequestModel> requests;
  final String message;

  AssetRequestActionSuccess(this.requests, this.message);
}
