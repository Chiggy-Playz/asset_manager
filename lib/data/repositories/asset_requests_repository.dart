import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/asset_request_model.dart';

class AssetRequestsRepository {
  final _supabase = Supabase.instance.client;

  /// Fetch all requests for the current user (their own requests)
  Future<List<AssetRequestModel>> fetchMyRequests() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('asset_requests')
        .select('''
          *,
          requester:profiles!requested_by(name),
          reviewer:profiles!reviewed_by(name),
          assets(tag_id)
        ''')
        .eq('requested_by', userId)
        .order('requested_at', ascending: false);

    return (response as List)
        .map((json) => AssetRequestModel.fromJson(json))
        .toList();
  }

  /// Fetch all pending requests (for admin review)
  Future<List<AssetRequestModel>> fetchPendingRequests() async {
    final response = await _supabase
        .from('asset_requests')
        .select('''
          *,
          requester:profiles!requested_by(name),
          reviewer:profiles!reviewed_by(name),
          assets(tag_id)
        ''')
        .eq('status', 'pending')
        .order('requested_at', ascending: true);

    return (response as List)
        .map((json) => AssetRequestModel.fromJson(json))
        .toList();
  }

  /// Fetch all requests (for admin view)
  Future<List<AssetRequestModel>> fetchAllRequests() async {
    final response = await _supabase
        .from('asset_requests')
        .select('''
          *,
          requester:profiles!requested_by(name),
          reviewer:profiles!reviewed_by(name),
          assets(tag_id)
        ''')
        .order('requested_at', ascending: false);

    return (response as List)
        .map((json) => AssetRequestModel.fromJson(json))
        .toList();
  }

  /// Create a new request
  Future<AssetRequestModel> createRequest({
    required String requestType,
    String? assetId,
    String? requestNotes,
    required Map<String, dynamic> requestData,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    final response = await _supabase
        .from('asset_requests')
        .insert({
          'asset_id': assetId,
          'request_type': requestType,
          'request_data': requestData,
          'requested_by': userId,
          'request_notes': requestNotes,
        })
        .select('''
          *,
          requester:profiles!requested_by(name),
          reviewer:profiles!reviewed_by(name),
          assets(tag_id)
        ''')
        .single();

    return AssetRequestModel.fromJson(response);
  }

  /// Approve and apply a request in one step (admin only)
  /// Returns the result including asset_id on success, or auto_rejected on conflict
  Future<Map<String, dynamic>> approveRequest(
    String requestId, {
    String? notes,
  }) async {
    final result = await _supabase.rpc('approve_and_apply_request', params: {
      'p_request_id': requestId,
      'p_notes': notes,
    });

    final response = result as Map<String, dynamic>;

    // Auto-rejection is a valid response (race condition with duplicate tag_id)
    // Don't throw, let the caller handle it
    if (response['success'] != true && response['auto_rejected'] != true) {
      throw Exception(response['error'] ?? 'Failed to approve request');
    }

    return response;
  }

  /// Reject a request (admin only)
  Future<void> rejectRequest(String requestId, {String? notes}) async {
    final result = await _supabase.rpc('reject_request', params: {
      'p_request_id': requestId,
      'p_notes': notes,
    });

    final response = result as Map<String, dynamic>;
    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Failed to reject request');
    }
  }

  /// Delete a request (admin only)
  Future<void> deleteRequest(String requestId) async {
    await _supabase.from('asset_requests').delete().eq('id', requestId);
  }
}
