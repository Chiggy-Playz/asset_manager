import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class UsersRepository {
  final SupabaseClient _client;

  UsersRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<ProfileModel>> fetchAllProfiles() async {
    final response = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ProfileModel.fromJson(json))
        .toList();
  }

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken}',
  };

  Future<void> inviteUser(String email) async {
    final response = await _client.functions.invoke(
      'invite-user',
      body: {'email': email},
      headers: _authHeaders,
    );

    if (response.status != 200) {
      final error = response.data['error'] as String? ?? 'Failed to invite user';
      throw Exception(error);
    }
  }

  Future<void> banUser(String userId) async {
    final response = await _client.functions.invoke(
      'ban-user',
      body: {'userId': userId, 'ban': true},
      headers: _authHeaders,
    );

    if (response.status != 200) {
      final error = response.data['error'] as String? ?? 'Failed to ban user';
      throw Exception(error);
    }
  }

  Future<void> unbanUser(String userId) async {
    final response = await _client.functions.invoke(
      'ban-user',
      body: {'userId': userId, 'ban': false},
      headers: _authHeaders,
    );

    if (response.status != 200) {
      final error = response.data['error'] as String? ?? 'Failed to unban user';
      throw Exception(error);
    }
  }
}
