import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/asset_request_model.dart';
import '../../../../data/models/location_model.dart';
import '../../../../shared/widgets/changes_detail_sheet.dart';
import '../../bloc/locations_bloc.dart';
import '../../bloc/locations_event.dart';
import '../../bloc/locations_state.dart';
import '../../../requests/bloc/asset_requests_bloc.dart';
import '../../../requests/bloc/asset_requests_event.dart';
import '../../../requests/bloc/asset_requests_state.dart';

class RequestsManagementPage extends StatefulWidget {
  const RequestsManagementPage({super.key});

  @override
  State<RequestsManagementPage> createState() => _RequestsManagementPageState();
}

class _RequestsManagementPageState extends State<RequestsManagementPage> {
  @override
  void initState() {
    super.initState();
    context.read<AssetRequestsBloc>().add(AllRequestsFetchRequested());
    context.read<LocationsBloc>().add(LocationsFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Requests')),
      body: BlocConsumer<AssetRequestsBloc, AssetRequestsState>(
        listener: (context, state) {
          if (state is AssetRequestActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AssetRequestsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AssetRequestsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = switch (state) {
            AssetRequestsLoaded s => s.requests,
            AssetRequestActionInProgress s => s.requests,
            AssetRequestActionSuccess s => s.requests,
            _ => <AssetRequestModel>[],
          };

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No requests yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Asset requests will appear here',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return BlocBuilder<LocationsBloc, LocationsState>(
            builder: (context, locState) {
              final locations = locState is LocationsLoaded
                  ? locState.locations
                  : <LocationModel>[];

              return ResponsiveBuilder(
                builder: (context, screenSize) {
                  final content = RefreshIndicator(
                    onRefresh: () async {
                      context.read<AssetRequestsBloc>().add(
                        AllRequestsFetchRequested(),
                      );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        final isProcessing =
                            state is AssetRequestActionInProgress &&
                            state.actionRequestId == request.id;
                        return _RequestHistoryCard(
                          request: request,
                          locations: locations,
                          isProcessing: isProcessing,
                          onApprove: request.isPending
                              ? () => _showApproveDialog(context, request)
                              : null,
                          onReject: request.isPending
                              ? () => _showRejectDialog(context, request)
                              : null,
                        );
                      },
                    ),
                  );

                  if (screenSize == ScreenSize.mobile) {
                    return content;
                  }

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: content,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showApproveDialog(BuildContext context, AssetRequestModel request) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to approve this ${request.displayType.toLowerCase()} request?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AssetRequestsBloc>().add(
                AssetRequestApproveRequested(
                  requestId: request.id,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                ),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AssetRequestModel request) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject this ${request.displayType.toLowerCase()} request?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Reason (recommended)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AssetRequestsBloc>().add(
                AssetRequestRejectRequested(
                  requestId: request.id,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _RequestHistoryCard extends StatelessWidget {
  final AssetRequestModel request;
  final List<LocationModel> locations;
  final bool isProcessing;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _RequestHistoryCard({
    required this.request,
    required this.locations,
    required this.isProcessing,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

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
                      color: typeColor.withOpacity(0.1),
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
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
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
                        dateFormat.format(request.requestedAt.toLocal()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              if (request.assetTagId != null)
                _buildDetailRow('Asset', request.assetTagId!),
              ...request.requestData.entries
                  .where(
                    (e) => e.value != null && e.value.toString().isNotEmpty,
                  )
                  .take(5)
                  .map(
                    (e) =>
                        _buildDetailRow(_formatKey(e.key), e.value.toString()),
                  ),
              if (request.requestData.entries
                      .where(
                        (e) => e.value != null && e.value.toString().isNotEmpty,
                      )
                      .length >
                  5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ more fields...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
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
                        color: theme.colorScheme.surfaceContainerHighest,
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
              if (request.isPending &&
                  (onApprove != null || onReject != null)) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onReject != null)
                      OutlinedButton(
                        onPressed: isProcessing ? null : onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        child: const Text('Reject'),
                      ),
                    if (onApprove != null) ...[
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
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetail(BuildContext context) async {
    ChangesDetailSheet.showFromRequest(
      context,
      request: request,
      locations: locations,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }
}
