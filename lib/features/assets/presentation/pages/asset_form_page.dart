import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/asset_model.dart';
import '../../bloc/assets_bloc.dart';
import '../../bloc/assets_state.dart';
import '../widgets/asset_edit_form.dart';

class AssetFormPage extends StatefulWidget {
  final String? assetId;

  const AssetFormPage({super.key, this.assetId});

  bool get isEditing => assetId != null;

  @override
  State<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<AssetFormPage> {
  final _formKey = GlobalKey<AssetEditFormState>();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  AssetModel? _findAsset(AssetsState state) {
    if (widget.assetId == null) return null;
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

  Future<bool> _onWillPop() async {
    final hasChanges = _formKey.currentState?.hasUnsavedChanges ?? false;
    if (!hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _handleEscape() async {
    final shouldPop = await _onWillPop();
    if (shouldPop && mounted) {
      context.pop();
    }
  }

  void _handleSave() {
    _formKey.currentState?.submit();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handleEscape,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _handleSave,
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) {
              context.pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.isEditing ? 'Edit Asset' : 'Add Asset'),
            ),
            body: BlocBuilder<AssetsBloc, AssetsState>(
              builder: (context, state) {
                final asset = _findAsset(state);

                return ResponsiveBuilder(
                  builder: (context, screenSize) {
                    final form = AssetEditForm(
                      key: _formKey,
                      asset: asset,
                      onSuccess: () => context.pop(),
                    );

                    if (screenSize == ScreenSize.mobile) {
                      return form;
                    }

                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: form,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
