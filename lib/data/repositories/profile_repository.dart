import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<ProfileModel?> fetchProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ProfileModel.fromJson(response);
  }

  Future<ProfileModel> createProfile({
    required String userId,
    required String name,
  }) async {
    final response = await _client.from('profiles').insert({
      'id': userId,
      'name': name,
    }).select().single();

    return ProfileModel.fromJson(response);
  }

  Future<ProfileModel> updateProfile({
    required String userId,
    required String name,
  }) async {
    final response = await _client
        .from('profiles')
        .update({'name': name})
        .eq('id', userId)
        .select()
        .single();

    return ProfileModel.fromJson(response);
  }
}
