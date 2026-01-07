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
  List<AssetAuditLogModel>? _auditLogs;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    context.read<LocationsBloc>().add(LocationsFetchRequested());
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await AssetsRepository().fetchAllAuditLogs();
      if (mounted) {
        setState(() {
          _auditLogs = logs;
          _isLoading = false;
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

    if (_auditLogs == null || _auditLogs!.isEmpty) {
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
      onRefresh: _loadAuditLogs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _auditLogs!.length,
        itemBuilder: (context, index) {
          final log = _auditLogs![index];
          return AuditLogCard(log: log, locations: locations);
        },
      ),
    );
  }
}
