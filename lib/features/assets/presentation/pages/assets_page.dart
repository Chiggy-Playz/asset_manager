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
import '../../bloc/assets_bloc.dart';
import '../../bloc/assets_event.dart';
import '../../bloc/assets_state.dart';
import '../utils/asset_dialogs.dart';
import '../widgets/asset_card.dart';
import '../widgets/asset_detail_content.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  String? _selectedAssetId;

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
          child: _buildListView(assets, locations, actionAssetId),
        );
      },
    );
  }

  Widget _buildDesktopView(BuildContext context, AssetsState state) {
    if (state is AssetsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final assets = _getAssets(state);
    final actionAssetId =
        state is AssetActionInProgress ? state.actionAssetId : null;

    if (assets.isEmpty) {
      return const Center(child: Text('No assets found'));
    }

    // Find the selected asset
    AssetModel? selectedAsset;
    if (_selectedAssetId != null) {
      try {
        selectedAsset = assets.firstWhere((a) => a.id == _selectedAssetId);
      } catch (_) {
        // Asset not found, clear selection
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedAssetId = null);
          }
        });
      }
    }

    return BlocBuilder<LocationsBloc, LocationsState>(
      builder: (context, locState) {
        final locations = _getLocations(locState);
        final theme = Theme.of(context);

        return Row(
          children: [
            SizedBox(
              width: 320,
              child: _buildListView(
                assets,
                locations,
                actionAssetId,
                selectedAssetId: _selectedAssetId,
              ),
            ),
            VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
            Expanded(
              child: selectedAsset != null
                  ? AssetDetailContent(
                      key: ValueKey(selectedAsset.id),
                      asset: selectedAsset,
                      onDeleted: () => setState(() => _selectedAssetId = null),
                    )
                  : _buildEmptyDetailPanel(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyDetailPanel(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Select an asset',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose an asset from the list to view its details',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(
    List<AssetModel> assets,
    List<LocationModel> locations,
    String? actionAssetId, {
    String? selectedAssetId,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final isSelected = selectedAssetId == asset.id;
        return AssetCard(
          asset: asset,
          isLoading: actionAssetId == asset.id,
          isSelected: isSelected,
          locationFullPath: _getLocationFullPath(
            asset.currentLocationId,
            locations,
          ),
          onTap: () {
            if (context.isMobile) {
              context.go(Routes.assetDetailPath(asset.id));
            } else {
              setState(() => _selectedAssetId = asset.id);
            }
          },
          onTransfer: () => AssetDialogs.showTransferDialog(context, asset),
          onEdit: () => context.go(Routes.assetEditPath(asset.id)),
          onDelete: () => AssetDialogs.showDeleteConfirmation(context, asset),
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
}
