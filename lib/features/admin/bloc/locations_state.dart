import '../../../data/models/location_model.dart';

sealed class LocationsState {}

class LocationsInitial extends LocationsState {}

class LocationsLoading extends LocationsState {}

class LocationsLoaded extends LocationsState {
  /// Flat list of all locations (with levels set)
  final List<LocationModel> locations;

  /// Tree structure for hierarchical display
  final List<LocationModel> locationTree;

  LocationsLoaded(this.locations, {this.locationTree = const []});
}

class LocationsError extends LocationsState {
  final String message;
  LocationsError(this.message);
}

class LocationActionInProgress extends LocationsState {
  final List<LocationModel> locations;
  final List<LocationModel> locationTree;
  final String? actionLocationId;
  LocationActionInProgress(
    this.locations, {
    this.locationTree = const [],
    this.actionLocationId,
  });
}

class LocationActionSuccess extends LocationsState {
  final List<LocationModel> locations;
  final List<LocationModel> locationTree;
  final String message;
  LocationActionSuccess(
    this.locations,
    this.message, {
    this.locationTree = const [],
  });
}
