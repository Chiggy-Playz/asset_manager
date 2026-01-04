import 'package:asset_manager/data/models/location_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/asset_model.dart';
import '../../../admin/bloc/locations_bloc.dart';
import '../../../admin/bloc/locations_event.dart';
import '../../../admin/bloc/locations_state.dart';
import '../../bloc/assets_bloc.dart';
import '../../bloc/assets_event.dart';
import '../../bloc/assets_state.dart';

class AssetFormPage extends StatefulWidget {
  final String? assetId;

  const AssetFormPage({super.key, this.assetId});

  bool get isEditing => assetId != null;

  @override
  State<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<AssetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _cpuController = TextEditingController();
  final _generationController = TextEditingController();
  final _ramController = TextEditingController();
  final _storageController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _modelNumberController = TextEditingController();
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    context.read<LocationsBloc>().add(LocationsFetchRequested());
    if (widget.isEditing) {
      _populateForm();
    }
  }

  void _populateForm() {
    final state = context.read<AssetsBloc>().state;
    final asset = _findAsset(state);
    if (asset != null) {
      _cpuController.text = asset.cpu ?? '';
      _generationController.text = asset.generation ?? '';
      _ramController.text = asset.ram ?? '';
      _storageController.text = asset.storage ?? '';
      _serialNumberController.text = asset.serialNumber ?? '';
      _modelNumberController.text = asset.modelNumber ?? '';
      _selectedLocationId = asset.currentLocationId;
    }
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
  void dispose() {
    _cpuController.dispose();
    _generationController.dispose();
    _ramController.dispose();
    _storageController.dispose();
    _serialNumberController.dispose();
    _modelNumberController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEditing) {
      // Don't update location here - use Transfer instead
      context.read<AssetsBloc>().add(AssetUpdateRequested(
            id: widget.assetId!,
            cpu: _cpuController.text.isEmpty ? null : _cpuController.text,
            generation: _generationController.text.isEmpty
                ? null
                : _generationController.text,
            ram: _ramController.text.isEmpty ? null : _ramController.text,
            storage:
                _storageController.text.isEmpty ? null : _storageController.text,
            serialNumber: _serialNumberController.text.isEmpty
                ? null
                : _serialNumberController.text,
            modelNumber: _modelNumberController.text.isEmpty
                ? null
                : _modelNumberController.text,
            currentLocationId: _selectedLocationId, // Keep original location
          ));
    } else {
      context.read<AssetsBloc>().add(AssetCreateRequested(
            cpu: _cpuController.text.isEmpty ? null : _cpuController.text,
            generation: _generationController.text.isEmpty
                ? null
                : _generationController.text,
            ram: _ramController.text.isEmpty ? null : _ramController.text,
            storage:
                _storageController.text.isEmpty ? null : _storageController.text,
            serialNumber: _serialNumberController.text.isEmpty
                ? null
                : _serialNumberController.text,
            modelNumber: _modelNumberController.text.isEmpty
                ? null
                : _modelNumberController.text,
            currentLocationId: _selectedLocationId,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AssetsBloc, AssetsState>(
      listener: (context, state) {
        if (state is AssetActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.pop();
        } else if (state is AssetsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Asset' : 'Add Asset'),
        ),
        body: ResponsiveBuilder(
          builder: (context, screenSize) {
            final content = _buildForm(context);
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
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return BlocBuilder<AssetsBloc, AssetsState>(
      builder: (context, assetsState) {
        final isLoading = assetsState is AssetActionInProgress;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _serialNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Model Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cpuController,
                  decoration: const InputDecoration(
                    labelText: 'CPU',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Intel Core i7',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _generationController,
                  decoration: const InputDecoration(
                    labelText: 'Generation',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 12th Gen',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ramController,
                  decoration: const InputDecoration(
                    labelText: 'RAM',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 16GB',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _storageController,
                  decoration: const InputDecoration(
                    labelText: 'Storage',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 512GB SSD',
                  ),
                ),
                const SizedBox(height: 16),
                BlocBuilder<LocationsBloc, LocationsState>(
                  builder: (context, locState) {
                    final locations =
                        locState is LocationsLoaded ? locState.locations : <LocationModel>[];

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedLocationId,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: const OutlineInputBorder(),
                        helperText: widget.isEditing
                            ? 'Use Transfer button to change location'
                            : null,
                      ),
                      items: locations
                          .map((loc) => DropdownMenuItem(
                                value: loc.id,
                                child: Text(loc.name),
                              ))
                          .toList(),
                      onChanged: widget.isEditing
                          ? null
                          : (value) {
                              setState(() {
                                _selectedLocationId = value;
                              });
                            },
                    );
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _onSubmit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isEditing ? 'Update Asset' : 'Create Asset'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }
}
