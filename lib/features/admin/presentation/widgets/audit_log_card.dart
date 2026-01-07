import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/asset_audit_log_model.dart';
import '../../../../data/models/location_model.dart';
import '../../../../shared/widgets/changes_detail_sheet.dart';

class AuditLogCard extends StatelessWidget {
  final AssetAuditLogModel log;
  final List<LocationModel> locations;

  const AuditLogCard({super.key, required this.log, required this.locations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    IconData actionIcon;
    Color actionColor;
    String actionTitle;

    switch (log.action) {
      case 'created':
        actionIcon = Icons.add_circle;
        actionColor = Colors.green;
        actionTitle = 'Asset Created';
      case 'updated':
        actionIcon = Icons.edit;
        actionColor = Colors.blue;
        actionTitle = 'Asset Updated';
      case 'transferred':
        actionIcon = Icons.swap_horiz;
        actionColor = Colors.orange;
        actionTitle = 'Asset Transferred';
      case 'deleted':
        actionIcon = Icons.delete;
        actionColor = Colors.red;
        actionTitle = 'Asset Deleted';
      default:
        actionIcon = Icons.info;
        actionColor = Colors.grey;
        actionTitle = log.action;
    }

    final tagId = _getTagId();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => ChangesDetailSheet.showFromAuditLog(
          context,
          log: log,
          locations: locations,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(actionIcon, color: actionColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            actionTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (tagId != null)
                      Text('Asset $tagId', style: theme.textTheme.bodyMedium),
                    Text(
                      'by ${log.userName ?? 'Unknown'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateFormat.format(log.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getTagId() {
    // Try to get tag_id from new_values or old_values
    final newTagId = log.newValues?['tag_id'];
    final oldTagId = log.oldValues?['tag_id'];
    final tagId = newTagId ?? oldTagId;
    return tagId?.toString();
  }
}
