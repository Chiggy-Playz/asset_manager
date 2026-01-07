import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/asset_model.dart';
import '../../../../router/routes.dart';
import '../../../admin/bloc/locations_bloc.dart';
import '../../../admin/bloc/locations_event.dart';
import '../../bloc/assets_bloc.dart';
import '../../bloc/assets_state.dart';
import '../utils/asset_dialogs.dart';
import '../widgets/asset_detail_content.dart';

class AssetDetailPage extends StatefulWidget {
  final String assetId;

  const AssetDetailPage({super.key, required this.assetId});

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<LocationsBloc>().add(LocationsFetchRequested());
  }

  AssetModel? _findAsset(AssetsState state) {
    final assets = switch (state) {
      AssetsLoaded s => s.assets,
      AssetActionInProgress s => s.assets,
      AssetActionSuccess s => s.assets,
      _ => <AssetModel>[],
    };
    try {
      return assets.firstWhere((a) => a.id == widget.assetId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssetsBloc, AssetsState>(
      listener: (context, state) {
        if (state is AssetActionSuccess && state.message == 'Asset deleted') {
          context.go(Routes.assets);
        }
      },
      builder: (context, state) {
        final asset = _findAsset(state);

        if (asset == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Asset Details')),
            body: const Center(child: Text('Asset not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Asset ${asset.tagId}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: 'Transfer',
                onPressed: () => AssetDialogs.showTransferDialog(context, asset),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () => context.go(Routes.assetEditPath(asset.id)),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: () => AssetDialogs.showDeleteConfirmation(context, asset),
              ),
            ],
          ),
          body: ResponsiveBuilder(
            builder: (context, screenSize) {
              final content = AssetDetailContent(
                asset: asset,
                showAppBar: false,
                onDeleted: () => context.go(Routes.assets),
              );

              if (screenSize == ScreenSize.mobile) {
                return content;
              }

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: content,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
