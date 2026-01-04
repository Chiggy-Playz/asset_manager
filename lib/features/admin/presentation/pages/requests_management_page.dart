import 'package:asset_manager/features/requests/presentation/widgets/request_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/asset_request_model.dart';
import '../../bloc/locations_bloc.dart';
import '../../bloc/locations_event.dart';
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
                    return RequestCard(request: request);
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
      ),
    );
  }
}
