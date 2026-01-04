import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/asset_audit_log_model.dart';
import '../models/asset_model.dart';

class AssetsRepository {
  final SupabaseClient _client;

  AssetsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<AssetModel>> fetchAssets() async {
    final response = await _client
        .from('assets')
        .select('*, locations(name)')
        .order('tag_id', ascending: true);

    return (response as List)
        .map((json) => AssetModel.fromJson(json))
        .toList();
  }

  Future<AssetModel?> fetchAsset(String id) async {
    final response = await _client
        .from('assets')
        .select('*, locations(name)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return AssetModel.fromJson(response);
  }

  Future<AssetModel> createAsset({
    required String tagId,
    String? cpu,
    String? generation,
    String? ram,
    String? storage,
    String? serialNumber,
    String? modelNumber,
    String? currentLocationId,
  }) async {
    final response = await _client.from('assets').insert({
      'tag_id': tagId,
      'cpu': cpu,
      'generation': generation,
      'ram': ram,
      'storage': storage,
      'serial_number': serialNumber,
      'model_number': modelNumber,
      'current_location_id': currentLocationId,
    }).select('*, locations(name)').single();

    return AssetModel.fromJson(response);
  }

  Future<AssetModel> updateAsset({
    required String id,
    String? cpu,
    String? generation,
    String? ram,
    String? storage,
    String? serialNumber,
    String? modelNumber,
    String? currentLocationId,
  }) async {
    final response = await _client
        .from('assets')
        .update({
          'cpu': cpu,
          'generation': generation,
          'ram': ram,
          'storage': storage,
          'serial_number': serialNumber,
          'model_number': modelNumber,
          'current_location_id': currentLocationId,
        })
        .eq('id', id)
        .select('*, locations(name)')
        .single();

    return AssetModel.fromJson(response);
  }

  Future<AssetModel> transferAsset({
    required String id,
    required String toLocationId,
  }) async {
    final response = await _client
        .from('assets')
        .update({'current_location_id': toLocationId})
        .eq('id', id)
        .select('*, locations(name)')
        .single();

    return AssetModel.fromJson(response);
  }

  Future<void> deleteAsset(String id) async {
    await _client.from('assets').delete().eq('id', id);
  }

  Future<List<AssetAuditLogModel>> fetchAssetHistory(String assetId) async {
    final response = await _client
        .from('asset_audit_logs')
        .select('*, profiles(name)')
        .eq('asset_id', assetId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AssetAuditLogModel.fromJson(json))
        .toList();
  }
}
