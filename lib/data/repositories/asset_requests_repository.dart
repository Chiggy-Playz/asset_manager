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

  /// Approve a request (admin only)
  Future<void> approveRequest(String requestId, {String? notes}) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase
        .from('asset_requests')
        .update({
          'status': 'approved',
          'reviewed_by': userId,
          'review_notes': notes,
        })
        .eq('id', requestId);
  }

  /// Reject a request (admin only)
  Future<void> rejectRequest(String requestId, {String? notes}) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase
        .from('asset_requests')
        .update({
          'status': 'rejected',
          'reviewed_by': userId,
          'review_notes': notes,
        })
        .eq('id', requestId);
  }

  /// Delete a request (admin only)
  Future<void> deleteRequest(String requestId) async {
    await _supabase.from('asset_requests').delete().eq('id', requestId);
  }
}
