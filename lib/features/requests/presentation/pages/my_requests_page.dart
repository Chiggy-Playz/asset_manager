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

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AssetRequestsBloc>().add(MyRequestsFetchRequested());
    context.read<LocationsBloc>().add(LocationsFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
      ),
      body: BlocBuilder<AssetRequestsBloc, AssetRequestsState>(
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
                    'Your asset modification requests will appear here',
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
                          .add(MyRequestsFetchRequested());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return _RequestCard(
                          request: request,
                          locations: locations,
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
                      constraints: const BoxConstraints(maxWidth: 600),
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
}

class _RequestCard extends StatelessWidget {
  final AssetRequestModel request;
  final List<LocationModel> locations;

  const _RequestCard({
    required this.request,
    required this.locations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

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

    IconData typeIcon;
    switch (request.requestType) {
      case AssetRequestType.create:
        typeIcon = Icons.add_circle_outline;
      case AssetRequestType.update:
        typeIcon = Icons.edit_outlined;
      case AssetRequestType.delete:
        typeIcon = Icons.delete_outline;
      case AssetRequestType.transfer:
        typeIcon = Icons.swap_horiz;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  Icon(typeIcon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.displayType,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                ],
              ),
              const SizedBox(height: 8),
              if (request.assetTagId != null)
                Text(
                  'Asset: ${request.assetTagId}',
                  style: theme.textTheme.bodyMedium,
                ),
              Text(
                'Submitted: ${dateFormat.format(request.requestedAt.toLocal())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              if (request.reviewedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Reviewed: ${dateFormat.format(request.reviewedAt!.toLocal())}',
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
}
