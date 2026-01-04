import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/field_option_model.dart';

class FieldOptionsRepository {
  final _supabase = Supabase.instance.client;

  Future<List<FieldOptionModel>> fetchAll() async {
    final response = await _supabase
        .from('field_options')
        .select()
        .order('field_name');

    return (response as List)
        .map((json) => FieldOptionModel.fromJson(json))
        .toList();
  }

  Future<FieldOptionModel?> fetchByFieldName(String fieldName) async {
    final response = await _supabase
        .from('field_options')
        .select()
        .eq('field_name', fieldName)
        .maybeSingle();

    if (response == null) return null;
    return FieldOptionModel.fromJson(response);
  }

  Future<void> updateFieldOption(
    String fieldName, {
    List<String>? options,
    bool? isRequired,
  }) async {
    final updates = <String, dynamic>{};
    if (options != null) updates['options'] = options;
    if (isRequired != null) updates['is_required'] = isRequired;

    if (updates.isNotEmpty) {
      await _supabase
          .from('field_options')
          .update(updates)
          .eq('field_name', fieldName);
    }
  }
}
