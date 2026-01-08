import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/location_selector.dart';
import '../../../../core/widgets/ram_module_editor.dart';
import '../../../../core/widgets/storage_device_editor.dart';
import '../../../../data/models/asset_model.dart';
import '../../../../data/models/location_model.dart';
import '../../../../data/models/ram_module_model.dart';
import '../../../../data/models/storage_device_model.dart';
import '../../../admin/bloc/field_options_bloc.dart';
import '../../../admin/bloc/field_options_event.dart';
import '../../../admin/bloc/field_options_state.dart';
import '../../../admin/bloc/locations_bloc.dart';
import '../../../admin/bloc/locations_event.dart';
import '../../../admin/bloc/locations_state.dart';
import '../../../profile/bloc/profile_bloc.dart';
import '../../../profile/bloc/profile_state.dart';
import '../../../requests/bloc/asset_requests_bloc.dart';
import '../../../requests/bloc/asset_requests_event.dart';
import '../../../requests/bloc/asset_requests_state.dart';
import '../../bloc/assets_bloc.dart';
import '../../bloc/assets_event.dart';
import '../../bloc/assets_state.dart';

class AssetEditForm extends StatefulWidget {
  /// The asset to edit. If null, this is a create form.
  final AssetModel? asset;

  /// Called when the form is successfully submitted.
  final VoidCallback? onSuccess;

  /// Called when the user cancels editing. If null, cancel button is hidden.
  final VoidCallback? onCancel;

  /// Whether to show action buttons (Cancel/Submit). Set to false if parent handles buttons.
  final bool showButtons;

  const AssetEditForm({
    super.key,
    this.asset,
    this.onSuccess,
    this.onCancel,
    this.showButtons = true,
  });

  bool get isEditing => asset != null;

  @override
  State<AssetEditForm> createState() => AssetEditFormState();
}

class AssetEditFormState extends State<AssetEditForm> {
  final _formKey = GlobalKey<FormState>();
  final _tagIdController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _requestNotesController = TextEditingController();

  String? _selectedCpu;
  String? _selectedGeneration;
  List<RamModuleModel> _ramModules = [];
  List<StorageDeviceModel> _storageDevices = [];
  String? _selectedModel;
  String? _selectedAssetType;
  String? _selectedLocationId;

  // Initial values for unsaved changes detection
  String _initialTagId = '';
  String _initialSerialNumber = '';
  String? _initialCpu;
  String? _initialGeneration;
  List<RamModuleModel> _initialRamModules = [];
  List<StorageDeviceModel> _initialStorageDevices = [];
  String? _initialModel;
  String? _initialAssetType;
  String? _initialLocationId;

  @override
  void initState() {
    super.initState();
    context.read<LocationsBloc>().add(LocationsFetchRequested());
    context.read<FieldOptionsBloc>().add(FieldOptionsFetchRequested());
    if (widget.isEditing) {
      _populateForm();
    }
    _saveInitialValues();
  }

  void _populateForm() {
    final asset = widget.asset!;
    _tagIdController.text = asset.tagId;
    _serialNumberController.text = asset.serialNumber ?? '';
    _selectedCpu = asset.cpu;
    _selectedGeneration = asset.generation;
    _ramModules = List.from(asset.ramModules);
    _storageDevices = List.from(asset.storageDevices);
    _selectedModel = asset.modelNumber;
    _selectedAssetType = asset.assetType;
    _selectedLocationId = asset.currentLocationId;
  }

  void _saveInitialValues() {
    _initialTagId = _tagIdController.text;
    _initialSerialNumber = _serialNumberController.text;
    _initialCpu = _selectedCpu;
    _initialGeneration = _selectedGeneration;
    _initialRamModules = List.from(_ramModules);
    _initialStorageDevices = List.from(_storageDevices);
    _initialModel = _selectedModel;
    _initialAssetType = _selectedAssetType;
    _initialLocationId = _selectedLocationId;
  }

  bool get hasUnsavedChanges {
    return _tagIdController.text != _initialTagId ||
        _serialNumberController.text != _initialSerialNumber ||
        _selectedCpu != _initialCpu ||
        _selectedGeneration != _initialGeneration ||
        !listEquals(_ramModules, _initialRamModules) ||
        !listEquals(_storageDevices, _initialStorageDevices) ||
        _selectedModel != _initialModel ||
        _selectedAssetType != _initialAssetType ||
        _selectedLocationId != _initialLocationId ||
        _requestNotesController.text.isNotEmpty;
  }

  bool get _isAdmin {
    final profileState = context.read<ProfileBloc>().state;
    return profileState is ProfileLoaded && profileState.profile.isAdmin;
  }

  /// Can be called externally to submit the form
  void submit() => _onSubmit();

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final requestData = {
      'tag_id': _tagIdController.text,
      'cpu': _selectedCpu,
      'generation': _selectedGeneration,
      'ram': _ramModules.map((m) => m.toJson()).toList(),
      'storage': _storageDevices.map((d) => d.toJson()).toList(),
      'serial_number': _serialNumberController.text.isEmpty
          ? null
          : _serialNumberController.text,
      'model_number': _selectedModel,
      'asset_type': _selectedAssetType,
      'current_location_id': _selectedLocationId,
    };

    if (_isAdmin) {
      if (widget.isEditing) {
        context.read<AssetsBloc>().add(
              AssetUpdateRequested(
                id: widget.asset!.id,
                cpu: _selectedCpu,
                generation: _selectedGeneration,
                ramModules: _ramModules,
                storageDevices: _storageDevices,
                serialNumber: _serialNumberController.text.isEmpty
                    ? null
                    : _serialNumberController.text,
                modelNumber: _selectedModel,
                assetType: _selectedAssetType,
                currentLocationId: _selectedLocationId,
              ),
            );
      } else {
        context.read<AssetsBloc>().add(
              AssetCreateRequested(
                tagId: _tagIdController.text,
                cpu: _selectedCpu,
                generation: _selectedGeneration,
                ramModules: _ramModules,
                storageDevices: _storageDevices,
                serialNumber: _serialNumberController.text.isEmpty
                    ? null
                    : _serialNumberController.text,
                modelNumber: _selectedModel,
                assetType: _selectedAssetType,
                currentLocationId: _selectedLocationId,
              ),
            );
      }
    } else {
      context.read<AssetRequestsBloc>().add(
            AssetRequestCreateRequested(
              requestType: widget.isEditing ? 'update' : 'create',
              assetId: widget.asset?.id,
              requestData: requestData,
              requestNotes: _requestNotesController.text.isEmpty
                  ? null
                  : _requestNotesController.text,
            ),
          );
    }
  }

  @override
  void dispose() {
    _tagIdController.dispose();
    _serialNumberController.dispose();
    _requestNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AssetsBloc, AssetsState>(
          listener: (context, state) {
            if (state is AssetActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              widget.onSuccess?.call();
            } else if (state is AssetsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        ),
        BlocListener<AssetRequestsBloc, AssetRequestsState>(
          listener: (context, state) {
            if (state is AssetRequestActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              widget.onSuccess?.call();
            } else if (state is AssetRequestsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        ),
      ],
      child: _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return BlocBuilder<AssetsBloc, AssetsState>(
      builder: (context, assetsState) {
        return BlocBuilder<AssetRequestsBloc, AssetRequestsState>(
          builder: (context, requestsState) {
            final isLoading = assetsState is AssetActionInProgress ||
                requestsState is AssetRequestActionInProgress;

            return BlocBuilder<FieldOptionsBloc, FieldOptionsState>(
              builder: (context, fieldOptionsState) {
                final fieldOptions = fieldOptionsState is FieldOptionsLoaded
                    ? fieldOptionsState
                    : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tag ID (only for new assets)
                        if (!widget.isEditing) ...[
                          TextFormField(
                            controller: _tagIdController,
                            decoration: const InputDecoration(
                              labelText: 'Tag ID *',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., CRS001',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tag ID is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Serial Number
                        TextFormField(
                          controller: _serialNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Serial Number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Model dropdown
                        _buildDropdownField(
                          label: 'Model',
                          value: _selectedModel,
                          options: fieldOptions?.getOptionsFor('model') ?? [],
                          onChanged: (v) => setState(() => _selectedModel = v),
                          isRequired:
                              fieldOptions?.isFieldRequired('model') ?? false,
                        ),
                        const SizedBox(height: 16),

                        // Asset Type dropdown
                        _buildDropdownField(
                          label: 'Asset Type',
                          value: _selectedAssetType,
                          options:
                              fieldOptions?.getOptionsFor('asset_type') ?? [],
                          onChanged: (v) =>
                              setState(() => _selectedAssetType = v),
                          isRequired:
                              fieldOptions?.isFieldRequired('asset_type') ??
                                  false,
                        ),
                        const SizedBox(height: 16),

                        // CPU dropdown
                        _buildDropdownField(
                          label: 'CPU',
                          value: _selectedCpu,
                          options: fieldOptions?.getOptionsFor('cpu') ?? [],
                          onChanged: (v) => setState(() => _selectedCpu = v),
                          isRequired:
                              fieldOptions?.isFieldRequired('cpu') ?? false,
                        ),
                        const SizedBox(height: 16),

                        // Generation dropdown
                        _buildDropdownField(
                          label: 'Generation',
                          value: _selectedGeneration,
                          options:
                              fieldOptions?.getOptionsFor('generation') ?? [],
                          onChanged: (v) =>
                              setState(() => _selectedGeneration = v),
                          isRequired:
                              fieldOptions?.isFieldRequired('generation') ??
                                  false,
                        ),
                        const SizedBox(height: 16),

                        // RAM Modules Editor
                        RamModuleEditor(
                          modules: _ramModules,
                          onChanged: (modules) =>
                              setState(() => _ramModules = modules),
                          sizeOptions:
                              fieldOptions?.getOptionsFor('ram_size') ?? [],
                          formFactorOptions:
                              fieldOptions?.getOptionsFor('ram_form_factor') ??
                                  [],
                          ddrTypeOptions:
                              fieldOptions?.getOptionsFor('ram_ddr_type') ?? [],
                        ),
                        const SizedBox(height: 16),

                        // Storage Devices Editor
                        StorageDeviceEditor(
                          devices: _storageDevices,
                          onChanged: (devices) =>
                              setState(() => _storageDevices = devices),
                          sizeOptions:
                              fieldOptions?.getOptionsFor('storage_size') ?? [],
                          typeOptions:
                              fieldOptions?.getOptionsFor('storage_type') ?? [],
                        ),
                        const SizedBox(height: 16),

                        // Location
                        BlocBuilder<LocationsBloc, LocationsState>(
                          builder: (context, locState) {
                            final locations = switch (locState) {
                              LocationsLoaded s => s.locations,
                              LocationActionInProgress s => s.locations,
                              LocationActionSuccess s => s.locations,
                              _ => <LocationModel>[],
                            };

                            if (widget.isEditing) {
                              final selectedLocation = locations
                                  .where((l) => l.id == _selectedLocationId)
                                  .firstOrNull;
                              return TextFormField(
                                enabled: false,
                                initialValue: selectedLocation != null
                                    ? selectedLocation.getFullPath(locations)
                                    : 'Not set',
                                decoration: const InputDecoration(
                                  labelText: 'Location',
                                  border: OutlineInputBorder(),
                                  helperText:
                                      'Use Transfer button to change location',
                                ),
                              );
                            }

                            return LocationSelector(
                              locations: locations,
                              selectedLocationId: _selectedLocationId,
                              onChanged: (value) {
                                setState(() => _selectedLocationId = value);
                              },
                              label: 'Location',
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Request notes for non-admin users
                        if (!_isAdmin) ...[
                          TextFormField(
                            controller: _requestNotesController,
                            decoration: const InputDecoration(
                              labelText: 'Request Notes',
                              border: OutlineInputBorder(),
                              hintText:
                                  'Provide additional details for your request',
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Info banner for non-admin users
                        if (!_isAdmin)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Your changes will be submitted for admin approval.',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Buttons
                        if (widget.showButtons)
                          _buildButtons(context, isLoading),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildButtons(BuildContext context, bool isLoading) {
    if (widget.onCancel != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : widget.onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: isLoading ? null : _onSubmit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isAdmin
                          ? (widget.isEditing ? 'Update Asset' : 'Create Asset')
                          : 'Submit Request',
                    ),
            ),
          ),
        ],
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : _onSubmit,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              _isAdmin
                  ? (widget.isEditing ? 'Update Asset' : 'Create Asset')
                  : 'Submit Request',
            ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    if (options.isEmpty) {
      return TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: const OutlineInputBorder(),
          helperText: 'No predefined options available',
        ),
        onChanged: onChanged,
        validator: isRequired
            ? (v) => v == null || v.isEmpty ? '$label is required' : null
            : null,
      );
    }

    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      items: options
          .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
          .toList(),
      onChanged: onChanged,
      validator: isRequired
          ? (v) => v == null || v.isEmpty ? '$label is required' : null
          : null,
    );
  }
}
