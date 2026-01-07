import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/asset_audit_log_model.dart';
import '../../../../data/models/location_model.dart';
import '../../../../data/repositories/assets_repository.dart';
import '../../bloc/locations_bloc.dart';
import '../../bloc/locations_event.dart';
import '../../bloc/locations_state.dart';
import '../widgets/audit_log_card.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  static const _pageSize = 20;

  final _scrollController = ScrollController();
  final _repository = AssetsRepository();

  List<AssetAuditLogModel> _auditLogs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    context.read<LocationsBloc>().add(LocationsFetchRequested());
    _scrollController.addListener(_onScroll);
    _loadAuditLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !_hasMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await _repository.fetchAllAuditLogs(
        limit: _pageSize,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _auditLogs = logs;
          _isLoading = false;
          _hasMore = logs.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final logs = await _repository.fetchAllAuditLogs(
        limit: _pageSize,
        offset: _auditLogs.length,
      );
      if (mounted) {
        setState(() {
          _auditLogs.addAll(logs);
          _isLoadingMore = false;
          _hasMore = logs.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more: $e')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    _hasMore = true;
    await _loadAuditLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
      ),
      body: BlocBuilder<LocationsBloc, LocationsState>(
        builder: (context, locState) {
          final locations = switch (locState) {
            LocationsLoaded s => s.locations,
            LocationActionInProgress s => s.locations,
            LocationActionSuccess s => s.locations,
            _ => <LocationModel>[],
          };

          return _buildBody(locations);
        },
      ),
    );
  }

  Widget _buildBody(List<LocationModel> locations) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load audit logs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadAuditLogs,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No audit logs yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Asset changes will appear here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _auditLogs.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _auditLogs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final log = _auditLogs[index];
          return AuditLogCard(log: log, locations: locations);
        },
      ),
    );
  }
}
