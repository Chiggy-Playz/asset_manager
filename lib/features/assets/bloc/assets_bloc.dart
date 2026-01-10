import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/asset_model.dart';
import '../../../data/repositories/assets_repository.dart';
import 'assets_event.dart';
import 'assets_state.dart';

class AssetsBloc extends Bloc<AssetsEvent, AssetsState> {
  final AssetsRepository _assetsRepository;
  static const int _pageSize = 25;

  List<AssetModel> _cachedAssets = [];
  bool _hasMore = true;

  AssetsBloc({required AssetsRepository assetsRepository})
    : _assetsRepository = assetsRepository,
      super(AssetsInitial()) {
    on<AssetsFetchRequested>(_onFetchRequested);
    on<AssetsLoadMoreRequested>(_onLoadMoreRequested);
    on<AssetCreateRequested>(_onCreateRequested);
    on<AssetUpdateRequested>(_onUpdateRequested);
    on<AssetDeleteRequested>(_onDeleteRequested);
    on<AssetTransferRequested>(_onTransferRequested);
  }

  Future<void> _onFetchRequested(
    AssetsFetchRequested event,
    Emitter<AssetsState> emit,
  ) async {
    emit(AssetsLoading());
    try {
      final assets = await _assetsRepository.fetchAssetsPaginated(
        limit: _pageSize,
        offset: 0,
      );
      _cachedAssets = assets;
      _hasMore = assets.length >= _pageSize;
      emit(AssetsLoaded(_cachedAssets, hasMore: _hasMore));
    } catch (e) {
      emit(AssetsError(e.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    AssetsLoadMoreRequested event,
    Emitter<AssetsState> emit,
  ) async {
    if (!_hasMore) return;

    final currentState = state;
    if (currentState is AssetsLoaded && currentState.isLoadingMore) return;

    emit(AssetsLoaded(_cachedAssets, hasMore: _hasMore, isLoadingMore: true));

    try {
      final newAssets = await _assetsRepository.fetchAssetsPaginated(
        limit: _pageSize,
        offset: _cachedAssets.length,
      );
      _cachedAssets = [..._cachedAssets, ...newAssets];
      _hasMore = newAssets.length >= _pageSize;
      emit(AssetsLoaded(_cachedAssets, hasMore: _hasMore));
    } catch (e) {
      emit(AssetsLoaded(_cachedAssets, hasMore: _hasMore));
    }
  }

  Future<void> _onCreateRequested(
    AssetCreateRequested event,
    Emitter<AssetsState> emit,
  ) async {
    emit(AssetActionInProgress(_cachedAssets, hasMore: _hasMore));
    try {
      final tagValidation = await _assetsRepository.validateTagId(event.tagId);
      if (tagValidation['valid'] != true) {
        String error = 'Tag ID is not available';
        if (tagValidation['exists_in_assets'] == true) {
          error = 'Tag ID already exists';
        } else if (tagValidation['exists_in_pending_requests'] == true) {
          error = 'Tag ID is pending approval in another request';
        }
        throw Exception(error);
      }

      await _assetsRepository.createAsset(
        tagId: event.tagId,
        cpu: event.cpu,
        generation: event.generation,
        ramModules: event.ramModules,
        storageDevices: event.storageDevices,
        serialNumber: event.serialNumber,
        modelNumber: event.modelNumber,
        assetType: event.assetType,
        currentLocationId: event.currentLocationId,
      );
      emit(AssetActionSuccess(_cachedAssets, 'Asset created', hasMore: _hasMore));
      add(AssetsFetchRequested());
    } catch (e) {
      emit(AssetsError(e.toString()));
      emit(AssetsLoaded(_cachedAssets, hasMore: _hasMore));
    }
  }

  Future<void> _onUpdateRequested(
    AssetUpdateRequested event,
    Emitter<AssetsState> emit,
  ) async {
    emit(AssetActionInProgress(_cachedAssets, actionAssetId: event.id, hasMore: _hasMore));
    try {
      await _assetsRepository.updateAsset(
        id: event.id,
        cpu: event.cpu,
        generation: event.generation,
        ramModules: event.ramModules,
        storageDevices: event.storageDevices,
        serialNumber: event.serialNumber,
        modelNumber: event.modelNumber,
        assetType: event.assetType,
        currentLocationId: event.currentLocationId,
      );
      emit(AssetActionSuccess(_cachedAssets, 'Asset updated', hasMore: _hasMore));
      add(AssetsFetchRequested());
    } catch (e) {
      emit(AssetsError(e.toString()));
      emit(AssetsLoaded(_cachedAssets, hasMore: _hasMore));
    }
  }

  Future<void> _onDeleteRequested(
    AssetDeleteRequested event,
    Emitter<AssetsState> emit,
  ) async {
    emit(AssetActionInProgress(_cachedAssets, actionAssetId: event.id, hasMore: _hasMore));
    try {
      await _assetsRepository.deleteAsset(event.id);
      emit(AssetActionSuccess(_cachedAssets, 'Asset deleted', hasMore: _hasMore));
      add(AssetsFetchRequested());
    } catch (e) {
      emit(AssetsError(e.toString()));
      emit(AssetsLoaded(_cachedAssets, hasMore: _hasMore));
    }
  }

  Future<void> _onTransferRequested(
    AssetTransferRequested event,
    Emitter<AssetsState> emit,
  ) async {
    emit(AssetActionInProgress(_cachedAssets, actionAssetId: event.id, hasMore: _hasMore));
    try {
      await _assetsRepository.transferAsset(
        id: event.id,
        toLocationId: event.toLocationId,
      );
      emit(AssetActionSuccess(_cachedAssets, 'Asset transferred', hasMore: _hasMore));
      add(AssetsFetchRequested());
    } catch (e) {
      emit(AssetsError(e.toString()));
      emit(AssetsLoaded(_cachedAssets, hasMore: _hasMore));
    }
  }
}
