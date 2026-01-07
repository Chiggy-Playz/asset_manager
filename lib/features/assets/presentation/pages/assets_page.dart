import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/asset_model.dart';
import '../../../../data/models/location_model.dart';
import '../../../../router/routes.dart';
import '../../../admin/bloc/locations_bloc.dart';
import '../../../admin/bloc/locations_event.dart';
import '../../../admin/bloc/locations_state.dart';
import '../../../profile/bloc/profile_bloc.dart';
import '../../../profile/bloc/profile_state.dart';
import '../../../requests/bloc/asset_requests_bloc.dart';
import '../../../requests/bloc/asset_requests_event.dart';
import '../../bloc/assets_bloc.dart';
import '../../bloc/assets_event.dart';
import '../../bloc/assets_state.dart';
import '../widgets/asset_card.dart';
import '../widgets/transfer_dialog.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AssetsBloc>().add(AssetsFetchRequested());
    context.read<LocationsBloc>().add(LocationsFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssetsBloc, AssetsState>(
      listener: (context, state) {
        if (state is AssetActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AssetsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Assets')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.go(Routes.assetCreate),
            icon: const Icon(Icons.add),
            label: const Text('Add Asset'),
          ),
          body: ResponsiveBuilder(
            builder: (context, screenSize) {
              if (screenSize == ScreenSize.mobile) {
                return _buildMobileView(context, state);
              }
              return _buildDesktopView(context, state);
            },
          ),
        );
      },
    );
  }

  Widget _buildMobileView(BuildContext context, AssetsState state) {
    if (state is AssetsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final assets = _getAssets(state);
    final actionAssetId = state is AssetActionInProgress
        ? state.actionAssetId
        : null;

    if (assets.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<AssetsBloc>().add(AssetsFetchRequested());
        },
        child: Stack(
          children: [
            ListView(),
            Center(
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
                    'No assets yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by adding new assets to your inventory',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<LocationsBloc, LocationsState>(
      builder: (context, locState) {
        final locations = _getLocations(locState);

        return RefreshIndicator(
          onRefresh: () async {
            context.read<AssetsBloc>().add(AssetsFetchRequested());
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return AssetCard(
                asset: asset,
                isLoading: actionAssetId == asset.id,
                locationFullPath: _getLocationFullPath(
                  asset.currentLocationId,
                  locations,
                ),
                onTap: () => context.go(Routes.assetDetailPath(asset.id)),
                onTransfer: () => _showTransferDialog(context, asset),
                onEdit: () => context.go(Routes.assetEditPath(asset.id)),
                onDelete: () => _showDeleteConfirmation(context, asset),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDesktopView(BuildContext context, AssetsState state) {
    if (state is AssetsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final assets = _getAssets(state);
    final actionAssetId = state is AssetActionInProgress
        ? state.actionAssetId
        : null;

    if (assets.isEmpty) {
      return const Center(child: Text('No assets found'));
    }

    return BlocBuilder<LocationsBloc, LocationsState>(
      builder: (context, locState) {
        final locations = _getLocations(locState);

        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Card(
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('Tag')),
                    DataColumn(label: Text('Serial Number')),
                    DataColumn(label: Text('Model')),
                    DataColumn(label: Text('CPU')),
                    DataColumn(label: Text('RAM')),
                    DataColumn(label: Text('Storage')),
                    DataColumn(label: Text('Location')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: assets.map((asset) {
                    final isLoading = actionAssetId == asset.id;
                    return DataRow(
                      onSelectChanged: (_) =>
                          context.go(Routes.assetDetailPath(asset.id)),
                      cells: [
                        DataCell(Text(asset.tagId)),
                        DataCell(Text(asset.serialNumber ?? '-')),
                        DataCell(Text(asset.modelNumber ?? '-')),
                        DataCell(Text(asset.cpu ?? '-')),
                        DataCell(Text(asset.ramSummary)),
                        DataCell(Text(asset.storageSummary)),
                        DataCell(
                          Text(
                            _getLocationFullPath(
                              asset.currentLocationId,
                              locations,
                            ),
                          ),
                        ),
                        DataCell(
                          isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.swap_horiz),
                                      tooltip: 'Transfer',
                                      onPressed: () =>
                                          _showTransferDialog(context, asset),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Edit',
                                      onPressed: () => context.go(
                                        Routes.assetEditPath(asset.id),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      tooltip: 'Delete',
                                      onPressed: () => _showDeleteConfirmation(
                                        context,
                                        asset,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<AssetModel> _getAssets(AssetsState state) {
    return switch (state) {
      AssetsLoaded s => s.assets,
      AssetActionInProgress s => s.assets,
      AssetActionSuccess s => s.assets,
      _ => [],
    };
  }

  List<LocationModel> _getLocations(LocationsState state) {
    return switch (state) {
      LocationsLoaded s => s.locations,
      LocationActionInProgress s => s.locations,
      LocationActionSuccess s => s.locations,
      _ => [],
    };
  }

  String _getLocationFullPath(
    String? locationId,
    List<LocationModel> locations,
  ) {
    if (locationId == null) return '-';
    if (locations.isEmpty) return '-';
    try {
      final location = locations.firstWhere((l) => l.id == locationId);
      return location.getFullPath(locations);
    } catch (_) {
      return '-';
    }
  }

  void _showTransferDialog(BuildContext context, AssetModel asset) {
    showDialog(
      context: context,
      builder: (dialogContext) => TransferDialog(
        currentLocationId: asset.currentLocationId,
        onTransfer: (locationId) {
          context.read<AssetsBloc>().add(
            AssetTransferRequested(id: asset.id, toLocationId: locationId),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AssetModel asset) {
    final profileState = context.read<ProfileBloc>().state;
    final isAdmin =
        profileState is ProfileLoaded && profileState.profile.isAdmin;

    if (isAdmin) {
      // Admin: Show simple confirmation and delete directly
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete Asset'),
          content: Text(
            'Are you sure you want to delete asset ${asset.tagId}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AssetsBloc>().add(AssetDeleteRequested(asset.id));
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      // Non-admin: Create a delete request
      final reasonController = TextEditingController();
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Request Asset Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request deletion of asset ${asset.tagId}. An admin will review your request.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Why should this asset be deleted?',
                  border: OutlineInputBorder(),
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
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AssetRequestsBloc>().add(
                  AssetRequestCreateRequested(
                    requestType: 'delete',
                    assetId: asset.id,
                    requestData: {},
                    requestNotes: reasonController.text.trim().isEmpty
                        ? null
                        : reasonController.text.trim(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delete request submitted for approval'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Request Deletion'),
            ),
          ],
        ),
      );
    }
  }
}
