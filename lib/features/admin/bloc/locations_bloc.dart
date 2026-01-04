import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/location_model.dart';
import '../../../data/repositories/locations_repository.dart';
import 'locations_event.dart';
import 'locations_state.dart';

class LocationsBloc extends Bloc<LocationsEvent, LocationsState> {
  final LocationsRepository _locationsRepository;
  List<LocationModel> _cachedLocations = [];

  LocationsBloc({required LocationsRepository locationsRepository})
      : _locationsRepository = locationsRepository,
        super(LocationsInitial()) {
    on<LocationsFetchRequested>(_onFetchRequested);
    on<LocationCreateRequested>(_onCreateRequested);
    on<LocationUpdateRequested>(_onUpdateRequested);
    on<LocationDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onFetchRequested(
    LocationsFetchRequested event,
    Emitter<LocationsState> emit,
  ) async {
    emit(LocationsLoading());
    try {
      final locations = await _locationsRepository.fetchLocations();
      _cachedLocations = locations;
      emit(LocationsLoaded(locations));
    } catch (e) {
      emit(LocationsError(e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    LocationCreateRequested event,
    Emitter<LocationsState> emit,
  ) async {
    emit(LocationActionInProgress(_cachedLocations));
    try {
      await _locationsRepository.createLocation(
        name: event.name,
        description: event.description,
      );
      emit(LocationActionSuccess(_cachedLocations, 'Location created'));
      add(LocationsFetchRequested());
    } catch (e) {
      emit(LocationsError(e.toString()));
      emit(LocationsLoaded(_cachedLocations));
    }
  }

  Future<void> _onUpdateRequested(
    LocationUpdateRequested event,
    Emitter<LocationsState> emit,
  ) async {
    emit(LocationActionInProgress(_cachedLocations, actionLocationId: event.id));
    try {
      await _locationsRepository.updateLocation(
        id: event.id,
        name: event.name,
        description: event.description,
      );
      emit(LocationActionSuccess(_cachedLocations, 'Location updated'));
      add(LocationsFetchRequested());
    } catch (e) {
      emit(LocationsError(e.toString()));
      emit(LocationsLoaded(_cachedLocations));
    }
  }

  Future<void> _onDeleteRequested(
    LocationDeleteRequested event,
    Emitter<LocationsState> emit,
  ) async {
    emit(LocationActionInProgress(_cachedLocations, actionLocationId: event.id));
    try {
      await _locationsRepository.deleteLocation(event.id);
      emit(LocationActionSuccess(_cachedLocations, 'Location deleted'));
      add(LocationsFetchRequested());
    } catch (e) {
      emit(LocationsError(e.toString()));
      emit(LocationsLoaded(_cachedLocations));
    }
  }
}
