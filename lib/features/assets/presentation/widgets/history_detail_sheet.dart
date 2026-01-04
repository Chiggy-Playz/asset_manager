import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/asset_audit_log_model.dart';
import '../../../../data/models/location_model.dart';

class HistoryDetailSheet extends StatelessWidget {
  final AssetAuditLogModel log;
  final List<LocationModel> locations;

  const HistoryDetailSheet({
    super.key,
    required this.log,
    required this.locations,
  });

  static void show(
    BuildContext context, {
    required AssetAuditLogModel log,
    required List<LocationModel> locations,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => HistoryDetailSheet(log: log, locations: locations),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localTime = log.createdAt.toLocal();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _getActionTitle(log.action),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'by ${log.userName ?? 'Unknown'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                _formatDateFull(localTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const Divider(height: 32),
              if (log.isTransferred)
                _buildTransferDetail(theme)
              else if (log.isUpdated)
                _buildUpdateDetail(theme)
              else if (log.isCreated)
                _buildCreatedDetail(theme)
              else
                const Text('No details available'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransferDetail(ThemeData theme) {
    final fromId = log.oldValues?['current_location_id'] as String?;
    final toId = log.newValues?['current_location_id'] as String?;

    String fromName = _getLocationName(fromId);
    String toName = _getLocationName(toId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transfer Details', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From', style: theme.textTheme.labelSmall),
                  Text(fromName, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('To', style: theme.textTheme.labelSmall),
                  Text(toName, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpdateDetail(ThemeData theme) {
    final changes = <Widget>[];
    final oldVals = log.oldValues ?? {};
    final newVals = log.newValues ?? {};

    final fieldsToCheck = [
      'cpu',
      'generation',
      'ram',
      'storage',
      'serial_number',
      'model_number',
    ];

    for (final field in fieldsToCheck) {
      final oldVal = oldVals[field]?.toString() ?? '';
      final newVal = newVals[field]?.toString() ?? '';
      if (oldVal != newVal) {
        changes.add(
          _buildChangeRow(
            _formatFieldName(field),
            oldVal.isEmpty ? '(empty)' : oldVal,
            newVal.isEmpty ? '(empty)' : newVal,
            theme,
          ),
        );
      }
    }

    if (changes.isEmpty) {
      return const Text('No field changes detected');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Changes', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        ...changes,
      ],
    );
  }

  Widget _buildCreatedDetail(ThemeData theme) {
    final newVals = log.newValues ?? {};
    final fields = <Widget>[];

    final fieldsToShow = {
      'serial_number': 'Serial Number',
      'model_number': 'Model Number',
      'cpu': 'CPU',
      'generation': 'Generation',
      'ram': 'RAM',
      'storage': 'Storage',
    };

    for (final entry in fieldsToShow.entries) {
      final val = newVals[entry.key]?.toString();
      if (val != null && val.isNotEmpty) {
        fields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entry.value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(child: Text(val)),
              ],
            ),
          ),
        );
      }
    }

    if (fields.isEmpty) {
      return const Text('Asset created with default values');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Initial Values', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        ...fields,
      ],
    );
  }

  Widget _buildChangeRow(
    String field,
    String oldVal,
    String newVal,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    oldVal,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    newVal,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLocationName(String? locationId) {
    if (locationId == null) return 'No Location';
    try {
      return locations.firstWhere((l) => l.id == locationId).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  String _getActionTitle(String action) {
    return switch (action) {
      'created' => 'Asset Created',
      'updated' => 'Asset Updated',
      'transferred' => 'Asset Transferred',
      'deleted' => 'Asset Deleted',
      _ => action,
    };
  }

  String _formatFieldName(String field) {
    return field
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  String _formatDateFull(DateTime date) {
    DateFormat dateFormat = DateFormat('dd MMM yyyy at HH:mm');
    return dateFormat.format(date);
  }
}
