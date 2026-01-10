import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/asset_audit_log_model.dart';
import '../models/asset_model.dart';
import '../models/asset_search_filter.dart';
import '../models/ram_module_model.dart';
import '../models/storage_device_model.dart';

class AssetsRepository {
  final SupabaseClient _client;

  AssetsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<AssetModel>> fetchAssets() async {
    final response = await _client
        .from('assets')
        .select('*, locations(name)')
        .order('tag_id', ascending: true);

    return (response as List).map((json) => AssetModel.fromJson(json)).toList();
  }

  /// Fetches assets with pagination support using limit/offset.
  Future<List<AssetModel>> fetchAssetsPaginated({
    int limit = 25,
    int offset = 0,
  }) async {
    final response = await _client
        .from('assets')
        .select('*, locations(name)')
        .order('tag_id', ascending: true)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) => AssetModel.fromJson(json)).toList();
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
    List<RamModuleModel>? ramModules,
    List<StorageDeviceModel>? storageDevices,
    String? serialNumber,
    String? modelNumber,
    String? assetType,
    String? currentLocationId,
  }) async {
    final response = await _client
        .from('assets')
        .insert({
          'tag_id': tagId,
          'cpu': cpu,
          'generation': generation,
          'ram': ramModules?.map((m) => m.toJson()).toList() ?? [],
          'storage': storageDevices?.map((d) => d.toJson()).toList() ?? [],
          'serial_number': serialNumber,
          'model_number': modelNumber,
          'asset_type': assetType,
          'current_location_id': currentLocationId,
        })
        .select('*, locations(name)')
        .single();

    return AssetModel.fromJson(response);
  }

  Future<AssetModel> updateAsset({
    required String id,
    String? cpu,
    String? generation,
    List<RamModuleModel>? ramModules,
    List<StorageDeviceModel>? storageDevices,
    String? serialNumber,
    String? modelNumber,
    String? assetType,
    String? currentLocationId,
  }) async {
    final response = await _client
        .from('assets')
        .update({
          'cpu': cpu,
          'generation': generation,
          'ram': ramModules?.map((m) => m.toJson()).toList(),
          'storage': storageDevices?.map((d) => d.toJson()).toList(),
          'serial_number': serialNumber,
          'model_number': modelNumber,
          'asset_type': assetType,
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
        .select('*, profiles(name), asset_requests(request_notes)')
        .eq('asset_id', assetId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AssetAuditLogModel.fromJson(json))
        .toList();
  }

  Future<List<AssetAuditLogModel>> fetchAllAuditLogs({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client
        .from('asset_audit_logs')
        .select('*, profiles(name), asset_requests(request_notes)')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AssetAuditLogModel.fromJson(json))
        .toList();
  }

  /// Validate tag_id uniqueness before creating a request
  Future<Map<String, dynamic>> validateTagId(
    String tagId, {
    String? excludeAssetId,
  }) async {
    final result = await _client.rpc(
      'validate_tag_id',
      params: {'p_tag_id': tagId, 'p_exclude_asset_id': excludeAssetId},
    );

    return result as Map<String, dynamic>;
  }

  /// Search assets with filters and pagination.
  /// Returns a [SearchResult] containing the matching assets and total count.
  Future<SearchResult<AssetModel>> searchAssets(
    AssetSearchFilter filter, {
    int page = 0,
    int pageSize = 25,
  }) async {
    final response = await _client.rpc(
      'search_assets',
      params: {
        'p_filters': filter.toJson(),
        'p_page_size': pageSize,
        'p_page_offset': page * pageSize,
        'p_count_only': false,
      },
    );

    final results = response as List;
    if (results.isEmpty) {
      return const SearchResult(assets: [], totalCount: 0);
    }

    // The total_count is the same for all rows
    final totalCount = (results.first['total_count'] as num?)?.toInt() ?? 0;

    // Parse assets from results
    final assets = results.map((json) {
      // Transform the flat result to match AssetModel.fromJson expected format
      final assetJson = {
        'id': json['id'],
        'tag_id': json['tag_id'],
        'serial_number': json['serial_number'],
        'model_number': json['model_number'],
        'asset_type': json['asset_type'],
        'cpu': json['cpu'],
        'generation': json['generation'],
        'ram': json['ram'],
        'storage': json['storage'],
        'current_location_id': json['current_location_id'],
        'created_at': json['created_at'],
        'updated_at': json['updated_at'],
        'locations': json['location_name'] != null
            ? {'name': json['location_name']}
            : null,
      };
      return AssetModel.fromJson(assetJson);
    }).toList();

    return SearchResult(assets: assets, totalCount: totalCount);
  }

  /// Count the total number of assets matching the filter.
  Future<int> countSearchResults(AssetSearchFilter filter) async {
    final response = await _client.rpc(
      'search_assets',
      params: {
        'p_filters': filter.toJson(),
        'p_page_size': 1,
        'p_page_offset': 0,
        'p_count_only': true,
      },
    );

    final results = response as List;
    if (results.isEmpty) return 0;

    return (results.first['total_count'] as num?)?.toInt() ?? 0;
  }

  /// Export all assets matching the filter (no pagination).
  /// Use with caution for large result sets.
  Future<List<AssetModel>> exportSearchResults(AssetSearchFilter filter) async {
    // Use a very large page size to get all results
    final result = await searchAssets(
      filter,
      page: 0,
      pageSize: 10000,
    );
    return result.assets;
  }
}
