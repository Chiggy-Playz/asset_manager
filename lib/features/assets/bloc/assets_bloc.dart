import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/asset_model.dart';
import '../../../data/repositories/assets_repository.dart';
import 'assets_event.dart';
import 'assets_state.dart';

class AssetsBloc extends Bloc<AssetsEvent, AssetsState> {
  final AssetsRepository _assetsRepository;
  List<AssetModel> _cachedAssets = [];

  AssetsBloc({required AssetsRepository assetsRepository})
    : _assetsRepository = assetsRepository,
      super(AssetsInitial()) {
    on<AssetsFetchRequested>(_onFetchRequested);
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
      final assets = await _assetsRepository.fetchAssets();
      _cachedAssets = assets;
      emit(AssetsLoaded(assets));
    } catch (e) {
      emit(AssetsError(e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    AssetCreateRequested event,
    Emitter<AssetsState> emit,
  ) async {
    emit(AssetActionInProgress(_cachedAssets));
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
        currentLocationId: event.currentLocationId,
      );
      emit(AssetActionSuccess(_cachedAssets, 'Asset created'));
      add(AssetsFetchRequested());
    } catch (e) {
      emit(AssetsError(e.toString()));
      emit(AssetsLoaded(_cachedAssets));
    }
  }

  Future<void> _onUpdateRequested(
    AssetUpdateRequested event,
    Emitter<AssetsState> emit,
  ) async {
    emit(AssetActionInProgress(_cachedAssets, actionAssetId: event.id));
    try {
      await _assetsRepository.updateAsset(
        id: event.id,
        cpu: event.cpu,
        generation: event.generation,
        ramModules: event.ramModules,
        storageDevices: event.storageDevices,
        serialNumber: event.serialNumber,
        modelNumber: event.modelNumber,
        currentLocationId: event.currentLocationId,
      );
      emit(AssetActionSuccess(_cachedAssets, 'Asset updated'));
      add(AssetsFetchRequested());
    } catch (e) {
      emit(AssetsError(e.toString()));
      emit(AssetsLoaded(_cachedAssets));
    }
  }

  Future<void> _onDeleteRequested(
    AssetDeleteRequested event,
    Emitter<AssetsState> emit,
  ) async {
    emit(AssetActionInProgress(_cachedAssets, actionAssetId: event.id));
    try {
      await _assetsRepository.deleteAsset(event.id);
      emit(AssetActionSuccess(_cachedAssets, 'Asset deleted'));
      add(AssetsFetchRequested());
    } catch (e) {
      emit(AssetsError(e.toString()));
      emit(AssetsLoaded(_cachedAssets));
    }
  }

  Future<void> _onTransferRequested(
    AssetTransferRequested event,
    Emitter<AssetsState> emit,
  ) async {
    emit(AssetActionInProgress(_cachedAssets, actionAssetId: event.id));
    try {
      await _assetsRepository.transferAsset(
        id: event.id,
        toLocationId: event.toLocationId,
      );
      emit(AssetActionSuccess(_cachedAssets, 'Asset transferred'));
      add(AssetsFetchRequested());
    } catch (e) {
      emit(AssetsError(e.toString()));
      emit(AssetsLoaded(_cachedAssets));
    }
  }
}
