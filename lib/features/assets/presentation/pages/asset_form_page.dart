import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/asset_model.dart';
import '../../../../data/models/location_model.dart';
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

class AssetFormPage extends StatefulWidget {
  final String? assetId;

  const AssetFormPage({super.key, this.assetId});

  bool get isEditing => assetId != null;

  @override
  State<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<AssetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tagIdController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _requestNotesController = TextEditingController();

  // Dropdown selections
  String? _selectedCpu;
  String? _selectedGeneration;
  String? _selectedRam;
  String? _selectedStorage;
  String? _selectedModel;
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    context.read<LocationsBloc>().add(LocationsFetchRequested());
    context.read<FieldOptionsBloc>().add(FieldOptionsFetchRequested());
    if (widget.isEditing) {
      _populateForm();
    }
  }

  void _populateForm() {
    final state = context.read<AssetsBloc>().state;
    final asset = _findAsset(state);
    if (asset != null) {
      _tagIdController.text = asset.tagId;
      _serialNumberController.text = asset.serialNumber ?? '';
      _selectedCpu = asset.cpu;
      _selectedGeneration = asset.generation;
      _selectedRam = asset.ram;
      _selectedStorage = asset.storage;
      _selectedModel = asset.modelNumber;
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

  bool get _isAdmin {
    final profileState = context.read<ProfileBloc>().state;
    return profileState is ProfileLoaded && profileState.profile.isAdmin;
  }

  @override
  void dispose() {
    _tagIdController.dispose();
    _serialNumberController.dispose();
    _requestNotesController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final requestData = {
      'tag_id': _tagIdController.text,
      'cpu': _selectedCpu,
      'generation': _selectedGeneration,
      'ram': _selectedRam,
      'storage': _selectedStorage,
      'serial_number': _serialNumberController.text.isEmpty
          ? null
          : _serialNumberController.text,
      'model_number': _selectedModel,
      'current_location_id': _selectedLocationId,
    };

    if (_isAdmin) {
      // Admin: Direct modification
      if (widget.isEditing) {
        context.read<AssetsBloc>().add(
          AssetUpdateRequested(
            id: widget.assetId!,
            cpu: _selectedCpu,
            generation: _selectedGeneration,
            ram: _selectedRam,
            storage: _selectedStorage,
            serialNumber: _serialNumberController.text.isEmpty
                ? null
                : _serialNumberController.text,
            modelNumber: _selectedModel,
            currentLocationId: _selectedLocationId,
          ),
        );
      } else {
        context.read<AssetsBloc>().add(
          AssetCreateRequested(
            tagId: _tagIdController.text,
            cpu: _selectedCpu,
            generation: _selectedGeneration,
            ram: _selectedRam,
            storage: _selectedStorage,
            serialNumber: _serialNumberController.text.isEmpty
                ? null
                : _serialNumberController.text,
            modelNumber: _selectedModel,
            currentLocationId: _selectedLocationId,
          ),
        );
      }
    } else {
      // User: Submit request for approval
      context.read<AssetRequestsBloc>().add(
        AssetRequestCreateRequested(
          requestType: widget.isEditing ? 'update' : 'create',
          assetId: widget.assetId,
          requestData: requestData,
          requestNotes: _requestNotesController.text.isEmpty
          ? null
          : _requestNotesController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AssetsBloc, AssetsState>(
          listener: (context, state) {
            if (state is AssetActionSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
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
        ),
        BlocListener<AssetRequestsBloc, AssetRequestsState>(
          listener: (context, state) {
            if (state is AssetRequestActionSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              context.pop();
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
        return BlocBuilder<AssetRequestsBloc, AssetRequestsState>(
          builder: (context, requestsState) {
            final isLoading =
                assetsState is AssetActionInProgress ||
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
                        if (!widget.isEditing)
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
                        if (!widget.isEditing) const SizedBox(height: 16),

                        // Serial Number (free text)
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

                        // RAM dropdown
                        _buildDropdownField(
                          label: 'RAM',
                          value: _selectedRam,
                          options: fieldOptions?.getOptionsFor('ram') ?? [],
                          onChanged: (v) => setState(() => _selectedRam = v),
                          isRequired:
                              fieldOptions?.isFieldRequired('ram') ?? false,
                        ),
                        const SizedBox(height: 16),

                        // Storage dropdown
                        _buildDropdownField(
                          label: 'Storage',
                          value: _selectedStorage,
                          options: fieldOptions?.getOptionsFor('storage') ?? [],
                          onChanged: (v) =>
                              setState(() => _selectedStorage = v),
                          isRequired:
                              fieldOptions?.isFieldRequired('storage') ?? false,
                        ),
                        const SizedBox(height: 16),

                        // Location dropdown
                        BlocBuilder<LocationsBloc, LocationsState>(
                          builder: (context, locState) {
                            final locations = locState is LocationsLoaded
                                ? locState.locations
                                : <LocationModel>[];

                            return DropdownButtonFormField<String>(
                              value: _selectedLocationId,
                              decoration: InputDecoration(
                                labelText: 'Location',
                                border: const OutlineInputBorder(),
                                helperText: widget.isEditing
                                    ? 'Use Transfer button to change location'
                                    : null,
                              ),
                              items: locations
                                  .map(
                                    (loc) => DropdownMenuItem(
                                      value: loc.id,
                                      child: Text(loc.name),
                                    ),
                                  )
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
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Your changes will be submitted for admin approval.',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        FilledButton(
                          onPressed: isLoading ? null : _onSubmit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isAdmin
                                      ? (widget.isEditing
                                            ? 'Update Asset'
                                            : 'Create Asset')
                                      : 'Submit Request',
                                ),
                        ),
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    // If options are empty, show a text field instead
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
