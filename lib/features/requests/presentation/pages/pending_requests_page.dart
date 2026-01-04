import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/asset_request_model.dart';
import '../../../../data/models/location_model.dart';
import '../../../../shared/widgets/changes_detail_sheet.dart';
import '../../../admin/bloc/locations_bloc.dart';
import '../../../admin/bloc/locations_event.dart';
import '../../../admin/bloc/locations_state.dart';
import '../../bloc/asset_requests_bloc.dart';
import '../../bloc/asset_requests_event.dart';
import '../../bloc/asset_requests_state.dart';

/// Page for admins to review pending requests (shown in navbar Requests tab)
class PendingRequestsPage extends StatefulWidget {
  const PendingRequestsPage({super.key});

  @override
  State<PendingRequestsPage> createState() => _PendingRequestsPageState();
}

class _PendingRequestsPageState extends State<PendingRequestsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AssetRequestsBloc>().add(PendingRequestsFetchRequested());
    context.read<LocationsBloc>().add(LocationsFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Requests'),
      ),
      body: BlocConsumer<AssetRequestsBloc, AssetRequestsState>(
        listener: (context, state) {
          if (state is AssetRequestActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All requests have been reviewed',
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
                      context
                          .read<AssetRequestsBloc>()
                          .add(PendingRequestsFetchRequested());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        final isProcessing =
                            state is AssetRequestActionInProgress &&
                                state.actionRequestId == request.id;
                        return _PendingRequestCard(
                          request: request,
                          locations: locations,
                          isProcessing: isProcessing,
                          onApprove: () => _showApproveDialog(context, request),
                          onReject: () => _showRejectDialog(context, request),
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
                'Are you sure you want to approve this ${request.displayType.toLowerCase()} request?'),
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
              context.read<AssetRequestsBloc>().add(AssetRequestApproveRequested(
                    requestId: request.id,
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  ));
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
                'Are you sure you want to reject this ${request.displayType.toLowerCase()} request?'),
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
              context.read<AssetRequestsBloc>().add(AssetRequestRejectRequested(
                    requestId: request.id,
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  ));
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

class _PendingRequestCard extends StatelessWidget {
  final AssetRequestModel request;
  final List<LocationModel> locations;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRequestCard({
    required this.request,
    required this.locations,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showRequestDetail(context),
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
                Text(
                  dateFormat.format(request.requestedAt.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (request.assetTagId != null)
              _buildDetailRow('Asset', request.assetTagId!),
            ...request.requestData.entries
                .where((e) => e.value != null && e.value.toString().isNotEmpty)
                .take(5)
                .map((e) => _buildDetailRow(
                      _formatKey(e.key),
                      e.value.toString(),
                    )),
            if (request.requestData.entries
                    .where(
                        (e) => e.value != null && e.value.toString().isNotEmpty)
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
            const SizedBox(height: 16),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showRequestDetail(BuildContext context) {
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
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
