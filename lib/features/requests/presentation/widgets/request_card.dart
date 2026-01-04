import 'package:asset_manager/data/models/asset_request_model.dart';
import 'package:asset_manager/features/profile/bloc/profile_bloc.dart';
import 'package:asset_manager/features/profile/bloc/profile_state.dart';
import 'package:asset_manager/features/requests/bloc/asset_requests_bloc.dart';
import 'package:asset_manager/features/requests/bloc/asset_requests_event.dart';
import 'package:asset_manager/features/requests/bloc/asset_requests_state.dart';
import 'package:asset_manager/shared/widgets/changes_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class RequestCard extends StatefulWidget {
  const RequestCard({super.key, required this.request});

  final AssetRequestModel request;

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  AssetRequestModel get request => widget.request;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        final isAdmin = switch (profileState) {
          ProfileLoaded p => p.profile.isAdmin,
          _ => false,
        };
        return BlocBuilder<AssetRequestsBloc, AssetRequestsState>(
          builder: (context, state) {
            final theme = Theme.of(context);
            final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

            IconData typeIcon;
            Color typeColor;
            switch (request.requestType) {
              case AssetRequestType.create:
                typeIcon = Icons.add_circle;
                typeColor = Colors.green;
              case AssetRequestType.update:
                typeIcon = Icons.edit;
                typeColor = Colors.blue;
              case AssetRequestType.delete:
                typeIcon = Icons.delete;
                typeColor = Colors.red;
              case AssetRequestType.transfer:
                typeIcon = Icons.swap_horiz;
                typeColor = Colors.orange;
            }

            Color statusColor;
            IconData statusIcon;
            switch (request.status) {
              case AssetRequestStatus.pending:
                statusColor = Colors.orange;
                statusIcon = Icons.hourglass_empty;
              case AssetRequestStatus.approved:
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              case AssetRequestStatus.rejected:
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
            }

            final isProcessing =
                state is AssetRequestActionInProgress &&
                state.actionRequestId == request.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () async => _showRequestDetail(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(typeIcon, color: typeColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.displayType,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'by ${request.requesterName ?? 'Unknown'}',
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      request.displayStatus,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: statusColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(
                                  request.requestedAt.toLocal(),
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (request.reviewedAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Reviewed: ${dateFormat.format(request.reviewedAt!.toLocal())}${request.reviewerName != null ? ' by ${request.reviewerName}' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (request.reviewNotes != null &&
                            request.reviewNotes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    size: 16,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      request.reviewNotes!,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                      if (isAdmin && request.isPending) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: isProcessing ? null : onReject,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                              ),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: isProcessing ? null : onApprove,
                              child: isProcessing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void onApprove() {
    _showRequestDialog(context, approve: true);
  }

  void onReject() {
    _showRequestDialog(context, approve: false);
  }

  void _showRequestDialog(BuildContext context, {required bool approve}) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve Request' : 'Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to '
              '${approve ? 'approve' : 'reject'} '
              'this ${request.displayType.toLowerCase()} request?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: approve
                    ? 'Notes (optional)'
                    : 'Reason (recommended)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: approve
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
            onPressed: () {
              Navigator.of(dialogContext).pop();

              final notes = notesController.text.isEmpty
                  ? null
                  : notesController.text;

              final bloc = context.read<AssetRequestsBloc>();

              if (approve) {
                bloc.add(
                  AssetRequestApproveRequested(
                    requestId: request.id,
                    notes: notes,
                  ),
                );
              } else {
                bloc.add(
                  AssetRequestRejectRequested(
                    requestId: request.id,
                    notes: notes,
                  ),
                );
              }
            },
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _showRequestDetail(BuildContext context) async {
    ChangesDetailSheet.showFromRequest(context, request: request);
  }
}
