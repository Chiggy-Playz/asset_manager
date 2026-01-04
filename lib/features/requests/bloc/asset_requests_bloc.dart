import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/asset_request_model.dart';
import '../../../data/repositories/asset_requests_repository.dart';
import 'asset_requests_event.dart';
import 'asset_requests_state.dart';

class AssetRequestsBloc extends Bloc<AssetRequestsEvent, AssetRequestsState> {
  final AssetRequestsRepository _repository;
  List<AssetRequestModel> _cachedRequests = [];

  AssetRequestsBloc({required AssetRequestsRepository repository})
    : _repository = repository,
      super(AssetRequestsInitial()) {
    on<MyRequestsFetchRequested>(_onMyRequestsFetch);
    on<PendingRequestsFetchRequested>(_onPendingRequestsFetch);
    on<AllRequestsFetchRequested>(_onAllRequestsFetch);
    on<AssetRequestCreateRequested>(_onCreateRequest);
    on<AssetRequestApproveRequested>(_onApproveRequest);
    on<AssetRequestRejectRequested>(_onRejectRequest);
  }

  Future<void> _onMyRequestsFetch(
    MyRequestsFetchRequested event,
    Emitter<AssetRequestsState> emit,
  ) async {
    emit(AssetRequestsLoading());
    try {
      final requests = await _repository.fetchMyRequests();
      _cachedRequests = requests;
      emit(AssetRequestsLoaded(requests));
    } catch (e) {
      emit(AssetRequestsError(e.toString()));
    }
  }

  Future<void> _onPendingRequestsFetch(
    PendingRequestsFetchRequested event,
    Emitter<AssetRequestsState> emit,
  ) async {
    emit(AssetRequestsLoading());
    try {
      final requests = await _repository.fetchPendingRequests();
      _cachedRequests = requests;
      emit(AssetRequestsLoaded(requests));
    } catch (e) {
      emit(AssetRequestsError(e.toString()));
    }
  }

  Future<void> _onAllRequestsFetch(
    AllRequestsFetchRequested event,
    Emitter<AssetRequestsState> emit,
  ) async {
    emit(AssetRequestsLoading());
    try {
      final requests = await _repository.fetchAllRequests();
      _cachedRequests = requests;
      emit(AssetRequestsLoaded(requests));
    } catch (e) {
      emit(AssetRequestsError(e.toString()));
    }
  }

  Future<void> _onCreateRequest(
    AssetRequestCreateRequested event,
    Emitter<AssetRequestsState> emit,
  ) async {
    emit(AssetRequestActionInProgress(_cachedRequests));
    try {
      await _repository.createRequest(
        requestType: event.requestType,
        assetId: event.assetId,
        requestData: event.requestData,
      );
      emit(AssetRequestActionSuccess(_cachedRequests, 'Request submitted'));
      add(MyRequestsFetchRequested());
    } catch (e) {
      emit(AssetRequestsError(e.toString()));
      emit(AssetRequestsLoaded(_cachedRequests));
    }
  }

  Future<void> _onApproveRequest(
    AssetRequestApproveRequested event,
    Emitter<AssetRequestsState> emit,
  ) async {
    emit(
      AssetRequestActionInProgress(
        _cachedRequests,
        actionRequestId: event.requestId,
      ),
    );
    try {
      final result = await _repository.approveRequest(
        event.requestId,
        notes: event.notes,
      );

      // Check for auto-rejection (duplicate tag_id race condition)
      if (result['auto_rejected'] == true) {
        throw Exception(result['error'] ?? 'Request was auto-rejected');
      }

      emit(
        AssetRequestActionSuccess(
          _cachedRequests,
          'Request approved and applied',
        ),
      );

      add(PendingRequestsFetchRequested());
    } catch (e) {
      emit(AssetRequestsError(e.toString()));
      // Still refresh the list in case the database state changed
      add(PendingRequestsFetchRequested());
    }
  }

  Future<void> _onRejectRequest(
    AssetRequestRejectRequested event,
    Emitter<AssetRequestsState> emit,
  ) async {
    emit(
      AssetRequestActionInProgress(
        _cachedRequests,
        actionRequestId: event.requestId,
      ),
    );
    try {
      await _repository.rejectRequest(event.requestId, notes: event.notes);
      emit(AssetRequestActionSuccess(_cachedRequests, 'Request rejected'));
      add(PendingRequestsFetchRequested());
    } catch (e) {
      emit(AssetRequestsError(e.toString()));
      emit(AssetRequestsLoaded(_cachedRequests));
    }
  }
}
