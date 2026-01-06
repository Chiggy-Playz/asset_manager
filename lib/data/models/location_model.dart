class LocationModel {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final String? parentId;
  final int level;
  final List<LocationModel> children;

  const LocationModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.parentId,
    this.level = 0,
    this.children = const [],
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      parentId: json['parent_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'parent_id': parentId,
    };
  }

  /// Creates a copy with updated fields
  LocationModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    String? parentId,
    int? level,
    List<LocationModel>? children,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      children: children ?? this.children,
    );
  }

  /// Returns the full path as "Building > Floor > Room"
  String getFullPath(List<LocationModel> allLocations) {
    final pathParts = <String>[];
    String? currentId = id;

    while (currentId != null) {
      final location = allLocations.firstWhere(
        (l) => l.id == currentId,
        orElse: () => this,
      );
      pathParts.insert(0, location.name);
      currentId = location.parentId;
    }

    return pathParts.join(' > ');
  }

  /// Gets all descendant IDs (for "include sub-levels" search)
  List<String> getAllDescendantIds() {
    final ids = <String>[];
    for (final child in children) {
      ids.add(child.id);
      ids.addAll(child.getAllDescendantIds());
    }
    return ids;
  }

  /// Checks if this location is a descendant of the given location ID
  bool isDescendantOf(String? ancestorId, List<LocationModel> allLocations) {
    if (ancestorId == null) return false;
    String? currentParentId = parentId;
    while (currentParentId != null) {
      if (currentParentId == ancestorId) return true;
      final parent = allLocations.firstWhere(
        (l) => l.id == currentParentId,
        orElse: () => this,
      );
      currentParentId = parent.parentId;
    }
    return false;
  }

  /// Whether this location can have children (max 3 levels, so level 2 cannot)
  bool get canHaveChildren => level < 2;
}
