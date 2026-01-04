import 'package:asset_manager/features/requests/presentation/widgets/request_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/asset_request_model.dart';
import '../../../admin/bloc/locations_bloc.dart';
import '../../../admin/bloc/locations_event.dart';
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
      appBar: AppBar(title: const Text('My Requests')),
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

          return ResponsiveBuilder(
            builder: (context, screenSize) {
              final content = RefreshIndicator(
                onRefresh: () async {
                  context.read<AssetRequestsBloc>().add(
                    MyRequestsFetchRequested(),
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
                  constraints: const BoxConstraints(maxWidth: 600),
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
