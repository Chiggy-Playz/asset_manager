import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/asset_audit_log_model.dart';
import '../../../../data/models/asset_model.dart';
import '../../../../data/models/location_model.dart';
import '../../../../data/repositories/assets_repository.dart';
import '../../../../router/routes.dart';
import '../../../admin/bloc/locations_bloc.dart';
import '../../../admin/bloc/locations_event.dart';
import '../../../admin/bloc/locations_state.dart';
import '../../bloc/assets_bloc.dart';
import '../../bloc/assets_event.dart';
import '../../bloc/assets_state.dart';
import '../widgets/history_detail_sheet.dart';
import '../widgets/transfer_dialog.dart';

class AssetDetailPage extends StatefulWidget {
  final String assetId;

  const AssetDetailPage({super.key, required this.assetId});

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  List<AssetAuditLogModel>? _auditLogs;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    context.read<LocationsBloc>().add(LocationsFetchRequested());
    _loadAuditHistory();
  }

  Future<void> _loadAuditHistory() async {
    try {
      final logs =
          await AssetsRepository().fetchAssetHistory(widget.assetId);
      if (mounted) {
        setState(() {
          _auditLogs = logs;
          _loadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingHistory = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssetsBloc, AssetsState>(
      listener: (context, state) {
        if (state is AssetActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          if (state.message == 'Asset deleted') {
            context.go(Routes.assets);
          } else {
            _loadAuditHistory();
          }
        } else if (state is AssetsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final asset = _findAsset(state);

        if (asset == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Asset Details')),
            body: const Center(child: Text('Asset not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Asset #${asset.tagId}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: 'Transfer',
                onPressed: () => _showTransferDialog(context, asset),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () => context.go(Routes.assetEditPath(asset.id)),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: () => _showDeleteConfirmation(context, asset),
              ),
            ],
          ),
          body: ResponsiveBuilder(
            builder: (context, screenSize) {
              final content = _buildContent(context, asset);
              if (screenSize == ScreenSize.mobile) {
                return content;
              }
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: content,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, AssetModel asset) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asset Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asset Information',
                      style: theme.textTheme.titleMedium),
                  const Divider(),
                  _buildInfoRow('Tag ID', '#${asset.tagId}'),
                  _buildInfoRow(
                    'Serial Number',
                    asset.serialNumber ?? '-',
                    copyable: asset.serialNumber != null,
                  ),
                  _buildInfoRow('Model Number', asset.modelNumber ?? '-'),
                  _buildInfoRow('CPU', asset.cpu ?? '-'),
                  _buildInfoRow('Generation', asset.generation ?? '-'),
                  _buildInfoRow('RAM', asset.ram ?? '-'),
                  _buildInfoRow('Storage', asset.storage ?? '-'),
                  _buildInfoRow('Location', asset.locationName ?? '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Audit History Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('History', style: theme.textTheme.titleMedium),
                  const Divider(),
                  if (_loadingHistory)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_auditLogs == null || _auditLogs!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No history available'),
                    )
                  else
                    BlocBuilder<LocationsBloc, LocationsState>(
                      builder: (context, locState) {
                        final locations = locState is LocationsLoaded
                            ? locState.locations
                            : <LocationModel>[];
                        return Column(
                          children: _auditLogs!
                              .map((log) =>
                                  _buildAuditLogItem(context, log, locations))
                              .toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: copyable && value != '-'
                ? InkWell(
                    onTap: () => _copyToClipboard(value),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: Text(value)),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.copy,
                            size: 14,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildAuditLogItem(
    BuildContext context,
    AssetAuditLogModel log,
    List<LocationModel> locations,
  ) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String title;
    String? subtitle;

    switch (log.action) {
      case 'created':
        icon = Icons.add_circle;
        color = Colors.green;
        title = 'Created';
      case 'updated':
        icon = Icons.edit;
        color = Colors.blue;
        title = 'Updated';
      case 'transferred':
        icon = Icons.swap_horiz;
        color = Colors.orange;
        title = 'Transferred';
        subtitle = _getTransferDescription(log, locations);
      case 'deleted':
        icon = Icons.delete;
        color = Colors.red;
        title = 'Deleted';
      default:
        icon = Icons.info;
        color = Colors.grey;
        title = log.action;
    }

    final localTime = log.createdAt.toLocal();

    return InkWell(
      onTap: () => HistoryDetailSheet.show(context, log: log, locations: locations),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  Text(
                    'by ${log.userName ?? 'Unknown'} on ${_formatDate(localTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String? _getTransferDescription(
    AssetAuditLogModel log,
    List<LocationModel> locations,
  ) {
    if (log.oldValues == null || log.newValues == null) return null;

    final fromId = log.oldValues!['current_location_id'] as String?;
    final toId = log.newValues!['current_location_id'] as String?;

    String fromName = 'Unknown';
    String toName = 'Unknown';

    if (fromId != null) {
      try {
        fromName = locations.firstWhere((l) => l.id == fromId).name;
      } catch (_) {
        fromName = 'Unknown';
      }
    } else {
      fromName = 'No Location';
    }

    if (toId != null) {
      try {
        toName = locations.firstWhere((l) => l.id == toId).name;
      } catch (_) {
        toName = 'Unknown';
      }
    } else {
      toName = 'No Location';
    }

    return '$fromName → $toName';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  AssetModel? _findAsset(AssetsState state) {
    final assets = switch (state) {
      AssetsLoaded s => s.assets,
      AssetActionInProgress s => s.assets,
      AssetActionSuccess s => s.assets,
      _ => <AssetModel>[],
    };
    try {
      return assets.firstWhere((a) => a.id == widget.assetId);
    } catch (_) {
      return null;
    }
  }

  void _showTransferDialog(BuildContext context, AssetModel asset) {
    showDialog(
      context: context,
      builder: (dialogContext) => TransferDialog(
        currentLocationId: asset.currentLocationId,
        onTransfer: (locationId) {
          context.read<AssetsBloc>().add(
                AssetTransferRequested(id: asset.id, toLocationId: locationId),
              );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AssetModel asset) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text(
          'Are you sure you want to delete asset #${asset.tagId}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AssetsBloc>().add(AssetDeleteRequested(asset.id));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
