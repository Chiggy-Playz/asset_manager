import 'package:asset_manager/features/admin/bloc/locations_bloc.dart';
import 'package:asset_manager/features/admin/bloc/locations_state.dart';
import 'package:asset_manager/features/profile/bloc/profile_bloc.dart';
import 'package:asset_manager/features/profile/bloc/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/asset_audit_log_model.dart';
import '../../data/models/asset_request_model.dart';
import '../../data/models/location_model.dart';

/// A shared widget to display change details for both:
/// - Asset audit logs (history)
/// - Asset requests (review)
class ChangesDetailSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? date;
  final ChangeType changeType;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;

  const ChangesDetailSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.date,
    required this.changeType,
    this.oldValues,
    this.newValues,
  });

  /// Show changes from an asset audit log
  static void showFromAuditLog(
    BuildContext context, {
    required AssetAuditLogModel log,
    required List<LocationModel> locations,
  }) {
    final localTime = log.createdAt.toLocal();
    final dateFormat = DateFormat('dd MMM yyyy at HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ChangesDetailSheet(
        title: _getActionTitle(log.action),
        subtitle: log.userName != null ? 'by ${log.userName}' : null,
        date: dateFormat.format(localTime),
        changeType: _actionToChangeType(log.action),
        oldValues: log.oldValues,
        newValues: log.newValues,
      ),
    );
  }

  /// Show changes from an asset request
  static void showFromRequest(
    BuildContext context, {
    required AssetRequestModel request,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy at HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ChangesDetailSheet(
        title: request.displayType,
        subtitle: request.requesterName != null
            ? 'by ${request.requesterName}'
            : null,
        date: dateFormat.format(request.requestedAt.toLocal()),
        changeType: _requestTypeToChangeType(request.requestType),
        oldValues: null, // Requests don't have old values
        newValues: request.requestData,
      ),
    );
  }

  static ChangeType _actionToChangeType(String action) {
    return switch (action) {
      'created' => ChangeType.create,
      'updated' => ChangeType.update,
      'transferred' => ChangeType.transfer,
      'deleted' => ChangeType.delete,
      _ => ChangeType.update,
    };
  }

  static ChangeType _requestTypeToChangeType(AssetRequestType type) {
    return switch (type) {
      AssetRequestType.create => ChangeType.create,
      AssetRequestType.update => ChangeType.update,
      AssetRequestType.transfer => ChangeType.transfer,
      AssetRequestType.delete => ChangeType.delete,
    };
  }

  static String _getActionTitle(String action) {
    return switch (action) {
      'created' => 'Asset Created',
      'updated' => 'Asset Updated',
      'transferred' => 'Asset Transferred',
      'deleted' => 'Asset Deleted',
      _ => action,
    };
  }

  @override
  State<ChangesDetailSheet> createState() => _ChangesDetailSheetState();
}

class _ChangesDetailSheetState extends State<ChangesDetailSheet> {
  List<LocationModel> locations = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<LocationsBloc, LocationsState>(
      listener: (context, locationState) {
        locations = switch (locationState) {
          LocationsLoaded l => l.locations,
          LocationActionInProgress l => l.locations,
          LocationActionSuccess l => l.locations,
          _ => <LocationModel>[],
        };
      },
      child: DraggableScrollableSheet(
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
                Text(widget.title, style: theme.textTheme.titleLarge),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
                if (widget.date != null)
                  Text(
                    widget.date!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                const Divider(height: 32),
                _buildContent(theme),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return switch (widget.changeType) {
      ChangeType.transfer => _buildTransferDetail(theme),
      ChangeType.update => _buildUpdateDetail(theme),
      ChangeType.create => _buildCreatedDetail(theme),
      ChangeType.delete => _buildDeleteDetail(theme),
    };
  }

  Widget _buildTransferDetail(ThemeData theme) {
    final fromId = widget.oldValues?['current_location_id'] as String?;
    final toId = widget.newValues?['current_location_id'] as String?;

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
    final oldVals = widget.oldValues ?? {};
    final newVals = widget.newValues ?? {};

    final fieldsToCheck = [
      'cpu',
      'generation',
      'ram',
      'storage',
      'serial_number',
      'model_number',
    ];

    // If we have old values, show diff (for history)
    if (widget.oldValues != null) {
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
    } else {
      // For requests, just show proposed values
      for (final field in fieldsToCheck) {
        final val = newVals[field]?.toString();
        if (val != null && val.isNotEmpty) {
          changes.add(_buildValueRow(_formatFieldName(field), val, theme));
        }
      }
    }

    if (changes.isEmpty) {
      return Text(
        widget.oldValues != null
            ? 'No field changes detected'
            : 'No changes specified',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.oldValues != null ? 'Changes' : 'Proposed Changes',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ...changes,
      ],
    );
  }

  Widget _buildCreatedDetail(ThemeData theme) {
    final newVals = widget.newValues ?? {};
    final fields = <Widget>[];

    final fieldsToShow = {
      'tag_id': 'Tag ID',
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
        fields.add(_buildValueRow(entry.value, val, theme));
      }
    }

    // Handle location
    final locationId = newVals['current_location_id'] as String?;
    if (locationId != null) {
      fields.add(
        _buildValueRow('Location', _getLocationName(locationId), theme),
      );
    }

    if (fields.isEmpty) {
      return Text(
        widget.oldValues != null
            ? 'Asset created with default values'
            : 'New asset with default values',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.oldValues != null ? 'Initial Values' : 'Proposed Values',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ...fields,
      ],
    );
  }

  Widget _buildDeleteDetail(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delete Details', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.oldValues != null
                      ? 'This asset was permanently deleted'
                      : 'This asset will be permanently deleted',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildValueRow(
    String label,
    String value,
    ThemeData theme, {
    bool isNew = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: isNew
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.green),
                    ),
                  )
                : Text(value),
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

  String _formatFieldName(String field) {
    return field
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }
}

enum ChangeType { create, update, transfer, delete }
