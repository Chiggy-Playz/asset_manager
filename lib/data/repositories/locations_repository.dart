import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/location_model.dart';

class LocationsRepository {
  final SupabaseClient _client;

  LocationsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetches all locations as a flat list
  Future<List<LocationModel>> fetchLocations() async {
    final response = await _client
        .from('locations')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((json) => LocationModel.fromJson(json))
        .toList();
  }

  /// Fetches locations and builds a tree structure with levels
  Future<List<LocationModel>> fetchLocationTree() async {
    final flatList = await fetchLocations();
    return _buildTree(flatList);
  }

  /// Builds a tree structure from flat list
  List<LocationModel> _buildTree(List<LocationModel> flatList) {
    // Create a map for quick lookup
    final Map<String, LocationModel> locationMap = {};
    for (final location in flatList) {
      locationMap[location.id] = location;
    }

    // Calculate levels for each location
    final Map<String, int> levelMap = {};
    for (final location in flatList) {
      levelMap[location.id] = _calculateLevel(location, locationMap);
    }

    // Update locations with their levels
    final locationsWithLevels = flatList.map((location) {
      return location.copyWith(level: levelMap[location.id] ?? 0);
    }).toList();

    // Build tree structure
    final rootLocations = <LocationModel>[];
    final Map<String, List<LocationModel>> childrenMap = {};

    for (final location in locationsWithLevels) {
      if (location.parentId == null) {
        rootLocations.add(location);
      } else {
        childrenMap.putIfAbsent(location.parentId!, () => []);
        childrenMap[location.parentId!]!.add(location);
      }
    }

    // Recursively attach children
    LocationModel attachChildren(LocationModel location) {
      final children = childrenMap[location.id] ?? [];
      final sortedChildren = children
        ..sort((a, b) => a.name.compareTo(b.name));
      return location.copyWith(
        children: sortedChildren.map(attachChildren).toList(),
      );
    }

    rootLocations.sort((a, b) => a.name.compareTo(b.name));
    return rootLocations.map(attachChildren).toList();
  }

  /// Calculates the level of a location in the hierarchy
  int _calculateLevel(
    LocationModel location,
    Map<String, LocationModel> locationMap,
  ) {
    int level = 0;
    String? currentParentId = location.parentId;
    while (currentParentId != null && level < 10) {
      level++;
      final parent = locationMap[currentParentId];
      currentParentId = parent?.parentId;
    }
    return level;
  }

  /// Flattens a tree into a list with correct levels preserved
  List<LocationModel> flattenTree(List<LocationModel> tree) {
    final result = <LocationModel>[];

    void traverse(LocationModel location) {
      result.add(location);
      for (final child in location.children) {
        traverse(child);
      }
    }

    for (final root in tree) {
      traverse(root);
    }

    return result;
  }

  Future<LocationModel?> fetchLocation(String id) async {
    final response = await _client
        .from('locations')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return LocationModel.fromJson(response);
  }

  Future<LocationModel> createLocation({
    required String name,
    String? description,
    String? parentId,
  }) async {
    final response = await _client.from('locations').insert({
      'name': name,
      'description': description,
      'parent_id': parentId,
    }).select().single();

    return LocationModel.fromJson(response);
  }

  Future<LocationModel> updateLocation({
    required String id,
    required String name,
    String? description,
    String? parentId,
  }) async {
    final response = await _client
        .from('locations')
        .update({
          'name': name,
          'description': description,
          'parent_id': parentId,
        })
        .eq('id', id)
        .select()
        .single();

    return LocationModel.fromJson(response);
  }

  Future<void> deleteLocation(String id) async {
    await _client.from('locations').delete().eq('id', id);
  }
}
