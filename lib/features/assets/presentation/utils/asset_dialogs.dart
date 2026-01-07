import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/asset_model.dart';
import '../../../profile/bloc/profile_bloc.dart';
import '../../../profile/bloc/profile_state.dart';
import '../../../requests/bloc/asset_requests_bloc.dart';
import '../../../requests/bloc/asset_requests_event.dart';
import '../../bloc/assets_bloc.dart';
import '../../bloc/assets_event.dart';
import '../widgets/transfer_dialog.dart';

class AssetDialogs {
  static void showTransferDialog(BuildContext context, AssetModel asset) {
    final profileState = context.read<ProfileBloc>().state;
    final isAdmin =
        profileState is ProfileLoaded && profileState.profile.isAdmin;
    showDialog(
      context: context,
      builder: (dialogContext) => TransferDialog(
        currentLocationId: asset.currentLocationId,
        onTransfer: (locationId) {
          if (isAdmin) {
            context.read<AssetsBloc>().add(
                  AssetTransferRequested(id: asset.id, toLocationId: locationId),
                );
          } else {
            context.read<AssetRequestsBloc>().add(
                  AssetRequestCreateRequested(
                    requestType: "transfer",
                    requestData: {"current_location_id": locationId},
                    assetId: asset.id,
                  ),
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transfer request submitted for approval'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  static void showDeleteConfirmation(BuildContext context, AssetModel asset) {
    final profileState = context.read<ProfileBloc>().state;
    final isAdmin =
        profileState is ProfileLoaded && profileState.profile.isAdmin;

    if (isAdmin) {
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
