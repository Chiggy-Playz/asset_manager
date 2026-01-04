sealed class LocationsEvent {}

class LocationsFetchRequested extends LocationsEvent {}

class LocationCreateRequested extends LocationsEvent {
  final String name;
  final String? description;
  LocationCreateRequested({required this.name, this.description});
}

class LocationUpdateRequested extends LocationsEvent {
  final String id;
  final String name;
  final String? description;
  LocationUpdateRequested({
    required this.id,
    required this.name,
    this.description,
  });
}

class LocationDeleteRequested extends LocationsEvent {
  final String id;
  LocationDeleteRequested(this.id);
}
