sealed class LocationsEvent {}

class LocationsFetchRequested extends LocationsEvent {}

class LocationCreateRequested extends LocationsEvent {
  final String name;
  final String? description;
  final String? parentId;
  LocationCreateRequested({
    required this.name,
    this.description,
    this.parentId,
  });
}

class LocationUpdateRequested extends LocationsEvent {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  LocationUpdateRequested({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
  });
}

class LocationDeleteRequested extends LocationsEvent {
  final String id;
  LocationDeleteRequested(this.id);
}
