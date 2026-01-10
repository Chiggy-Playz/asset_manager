import '../../../data/models/asset_model.dart';

sealed class AssetsState {}

class AssetsInitial extends AssetsState {}

class AssetsLoading extends AssetsState {}

class AssetsLoaded extends AssetsState {
  final List<AssetModel> assets;
  final bool hasMore;
  final bool isLoadingMore;

  AssetsLoaded(
    this.assets, {
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  AssetsLoaded copyWith({
    List<AssetModel>? assets,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return AssetsLoaded(
      assets ?? this.assets,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class AssetsError extends AssetsState {
  final String message;
  AssetsError(this.message);
}

class AssetActionInProgress extends AssetsState {
  final List<AssetModel> assets;
  final String? actionAssetId;
  final bool hasMore;
  AssetActionInProgress(this.assets, {this.actionAssetId, this.hasMore = true});
}

class AssetActionSuccess extends AssetsState {
  final List<AssetModel> assets;
  final String message;
  final bool hasMore;
  AssetActionSuccess(this.assets, this.message, {this.hasMore = true});
}
