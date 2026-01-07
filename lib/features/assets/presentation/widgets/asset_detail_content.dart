import 'package:asset_manager/features/assets/bloc/assets_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/asset_audit_log_model.dart';
import '../../../../data/models/asset_model.dart';
import '../../../../data/models/location_model.dart';
import '../../../../data/repositories/assets_repository.dart';
import '../../../../shared/widgets/changes_detail_sheet.dart';
import '../../../admin/bloc/locations_bloc.dart';
import '../../../admin/bloc/locations_state.dart';
import '../../bloc/assets_bloc.dart';
import '../../bloc/assets_state.dart';
import '../utils/asset_dialogs.dart';
import 'asset_edit_form.dart';

class AssetDetailContent extends StatefulWidget {
  final AssetModel asset;
  final bool showAppBar;
  final VoidCallback? onDeleted;

  const AssetDetailContent({
    super.key,
    required this.asset,
    this.showAppBar = true,
    this.onDeleted,
  });

  @override
  State<AssetDetailContent> createState() => _AssetDetailContentState();
}

class _AssetDetailContentState extends State<AssetDetailContent> {
  List<AssetAuditLogModel>? _auditLogs;
  bool _loadingHistory = true;
  bool _isEditing = false;
  final _editFormKey = GlobalKey<AssetEditFormState>();

  @override
  void initState() {
    super.initState();
    _loadAuditHistory();
  }

  @override
  void didUpdateWidget(AssetDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _loadAuditHistory();
      _isEditing = false;
    }
  }

  Future<void> _loadAuditHistory() async {
    setState(() {
      _loadingHistory = true;
      _auditLogs = null;
    });
    try {
      final logs = await AssetsRepository().fetchAssetHistory(widget.asset.id);
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

  Future<void> _onRefresh() async {
    context.read<AssetsBloc>().add(AssetsFetchRequested());
    await _loadAuditHistory();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  Future<void> _cancelEditing() async {
    final hasChanges = _editFormKey.currentState?.hasUnsavedChanges ?? false;
    if (hasChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to cancel?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (result != true) return;
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AssetsBloc, AssetsState>(
      listener: (context, state) {
        if (state is AssetActionSuccess) {
          if (state.message == 'Asset deleted') {
            widget.onDeleted?.call();
          } else {
            _loadAuditHistory();
          }
        }
      },
      child: widget.showAppBar
          ? Column(
              children: [
                _isEditing ? _buildEditHeader(context) : _buildHeader(context),
                Expanded(
                  child: _isEditing
                      ? _buildConstrainedEditForm(
                          onSuccess: () {
                            setState(() => _isEditing = false);
                            _loadAuditHistory();
                          },
                        )
                      : _buildBody(context),
                ),
              ],
            )
          : _isEditing
          ? _buildConstrainedEditForm(
              onSuccess: () => setState(() => _isEditing = false),
            )
          : _buildBody(context),
    );
  }

  Widget _buildConstrainedEditForm({required VoidCallback onSuccess}) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: AssetEditForm(
          key: _editFormKey,
          asset: widget.asset,
          onSuccess: onSuccess,
          onCancel: _cancelEditing,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Asset ${widget.asset.tagId}',
              style: theme.textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Transfer',
            onPressed: () =>
                AssetDialogs.showTransferDialog(context, widget.asset),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: _startEditing,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () =>
                AssetDialogs.showDeleteConfirmation(context, widget.asset),
          ),
        ],
      ),
    );
  }

  Widget _buildEditHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: _cancelEditing,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Edit Asset ${widget.asset.tagId}',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context, theme),
            const SizedBox(height: 16),
            _buildHistoryCard(context, theme),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asset Information', style: theme.textTheme.titleMedium),
            const Divider(),
            _buildInfoRow('Tag ID', widget.asset.tagId),
            _buildInfoRow(
              'Serial Number',
              widget.asset.serialNumber ?? '-',
              copyable: widget.asset.serialNumber != null,
            ),
            _buildInfoRow('Model Number', widget.asset.modelNumber ?? '-'),
            _buildInfoRow('CPU', widget.asset.cpu ?? '-'),
            _buildInfoRow('Generation', widget.asset.generation ?? '-'),
            _buildInfoRow(
              'RAM',
              widget.asset.ramModules.isEmpty
                  ? '-'
                  : widget.asset.ramModules
                        .map((m) => m.displayText)
                        .join("\n"),
            ),
            _buildInfoRow(
              'Storage',
              widget.asset.storageDevices.isEmpty
                  ? '-'
                  : widget.asset.storageDevices
                        .map((d) => d.displayText)
                        .join("\n"),
            ),
            BlocBuilder<LocationsBloc, LocationsState>(
              builder: (context, locState) {
                final locations = switch (locState) {
                  LocationsLoaded s => s.locations,
                  LocationActionInProgress s => s.locations,
                  LocationActionSuccess s => s.locations,
                  _ => <LocationModel>[],
                };
                return _buildInfoRow(
                  'Location',
                  _getLocationFullPath(
                    widget.asset.currentLocationId,
                    locations,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ThemeData theme) {
    return Card(
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
                  final locations = switch (locState) {
                    LocationsLoaded s => s.locations,
                    LocationActionInProgress s => s.locations,
                    LocationActionSuccess s => s.locations,
                    _ => <LocationModel>[],
                  };
                  return Column(
                    children: _auditLogs!
                        .map(
                          (log) => _buildAuditLogItem(context, log, locations),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ),
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
                      padding: const EdgeInsets.symmetric(vertical: 2),
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
      onTap: () => ChangesDetailSheet.showFromAuditLog(
        context,
        log: log,
        locations: locations,
      ),
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
                    Text(subtitle, style: theme.textTheme.bodySmall),
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

  String _getLocationFullPath(
    String? locationId,
    List<LocationModel> locations,
  ) {
    if (locationId == null) return '-';
    if (locations.isEmpty) return '-';
    try {
      final location = locations.firstWhere((l) => l.id == locationId);
      return location.getFullPath(locations);
    } catch (_) {
      return '-';
    }
  }

  String? _getTransferDescription(
    AssetAuditLogModel log,
    List<LocationModel> locations,
  ) {
    if (log.oldValues == null || log.newValues == null) return null;

    final fromId = log.oldValues!['current_location_id'] as String?;
    final toId = log.newValues!['current_location_id'] as String?;

    final fromName = fromId != null
        ? _getLocationFullPath(fromId, locations)
        : 'No Location';
    final toName = toId != null
        ? _getLocationFullPath(toId, locations)
        : 'No Location';

    return '$fromName → $toName';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
