import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/location_model.dart';

class LocationsRepository {
  final SupabaseClient _client;

  LocationsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<LocationModel>> fetchLocations() async {
    final response = await _client
        .from('locations')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((json) => LocationModel.fromJson(json))
        .toList();
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
  }) async {
    final response = await _client.from('locations').insert({
      'name': name,
      'description': description,
    }).select().single();

    return LocationModel.fromJson(response);
  }

  Future<LocationModel> updateLocation({
    required String id,
    required String name,
    String? description,
  }) async {
    final response = await _client
        .from('locations')
        .update({
          'name': name,
          'description': description,
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
