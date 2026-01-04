import '../../../data/models/location_model.dart';

sealed class LocationsState {}

class LocationsInitial extends LocationsState {}

class LocationsLoading extends LocationsState {}

class LocationsLoaded extends LocationsState {
  final List<LocationModel> locations;
  LocationsLoaded(this.locations);
}

class LocationsError extends LocationsState {
  final String message;
  LocationsError(this.message);
}

class LocationActionInProgress extends LocationsState {
  final List<LocationModel> locations;
  final String? actionLocationId;
  LocationActionInProgress(this.locations, {this.actionLocationId});
}

class LocationActionSuccess extends LocationsState {
  final List<LocationModel> locations;
  final String message;
  LocationActionSuccess(this.locations, this.message);
}
