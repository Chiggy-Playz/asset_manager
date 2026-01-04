import 'package:flutter/material.dart';

import '../../../../data/models/asset_audit_log_model.dart';
import '../../../../data/models/location_model.dart';
import '../../../../shared/widgets/changes_detail_sheet.dart';

/// Widget to show asset history log details.
/// This is a convenience wrapper around ChangesDetailSheet for audit logs.
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
    ChangesDetailSheet.showFromAuditLog(
      context,
      log: log,
      locations: locations,
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget is only used via the static show method
    // But we implement build for completeness
    return ChangesDetailSheet(
      title: _getActionTitle(log.action),
      subtitle: log.userName != null ? 'by ${log.userName}' : null,
      changeType: _actionToChangeType(log.action),
      oldValues: log.oldValues,
      newValues: log.newValues,
      locations: locations,
    );
  }

  ChangeType _actionToChangeType(String action) {
    return switch (action) {
      'created' => ChangeType.create,
      'updated' => ChangeType.update,
      'transferred' => ChangeType.transfer,
      'deleted' => ChangeType.delete,
      _ => ChangeType.update,
    };
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
}
