import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/update_info_model.dart';

class UpdateRepository {
  final SupabaseClient _client;

  UpdateRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<UpdateInfoModel> checkForUpdate() async {
    final response = await _client.functions.invoke('check-update');

    if (response.status != 200) {
      final error = response.data['error'] as String? ?? 'Unknown error';
      throw Exception(error);
    }

    return UpdateInfoModel.fromJson(response.data as Map<String, dynamic>);
  }
}
