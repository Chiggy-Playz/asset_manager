import '../../../data/models/asset_model.dart';

sealed class AssetsState {}

class AssetsInitial extends AssetsState {}

class AssetsLoading extends AssetsState {}

class AssetsLoaded extends AssetsState {
  final List<AssetModel> assets;
  AssetsLoaded(this.assets);
}

class AssetsError extends AssetsState {
  final String message;
  AssetsError(this.message);
}

class AssetActionInProgress extends AssetsState {
  final List<AssetModel> assets;
  final String? actionAssetId;
  AssetActionInProgress(this.assets, {this.actionAssetId});
}

class AssetActionSuccess extends AssetsState {
  final List<AssetModel> assets;
  final String message;
  AssetActionSuccess(this.assets, this.message);
}
