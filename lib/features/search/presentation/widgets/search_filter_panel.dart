import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/asset_search_filter.dart';
import '../../../../data/models/location_model.dart';
import '../../../admin/bloc/field_options_bloc.dart';
import '../../../admin/bloc/field_options_state.dart';
import '../../../admin/bloc/locations_bloc.dart';
import '../../../admin/bloc/locations_state.dart';
import 'multi_select_filter.dart';
import 'size_comparison_filter.dart';

class SearchFilterPanel extends StatefulWidget {
  final AssetSearchFilter filter;
  final ValueChanged<AssetSearchFilter> onFilterChanged;
  final VoidCallback onSearch;

  const SearchFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearch,
  });

  @override
  State<SearchFilterPanel> createState() => _SearchFilterPanelState();
}

class _SearchFilterPanelState extends State<SearchFilterPanel> {
  late TextEditingController _tagIdController;
  late TextEditingController _serialNumberController;
  late TextEditingController _modelNumberController;

  // Local state for filter values
  late AssetSearchFilter _localFilter;

  @override
  void initState() {
    super.initState();
    _localFilter = widget.filter;
    _tagIdController = TextEditingController(text: widget.filter.tagId ?? '');
    _serialNumberController = TextEditingController(
      text: widget.filter.serialNumber ?? '',
    );
    _modelNumberController = TextEditingController(
      text: widget.filter.modelNumber ?? '',
    );
  }

  @override
  void didUpdateWidget(SearchFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter != oldWidget.filter) {
      _localFilter = widget.filter;
      _tagIdController.text = widget.filter.tagId ?? '';
      _serialNumberController.text = widget.filter.serialNumber ?? '';
      _modelNumberController.text = widget.filter.modelNumber ?? '';
    }
  }

  @override
  void dispose() {
    _tagIdController.dispose();
    _serialNumberController.dispose();
    _modelNumberController.dispose();
    super.dispose();
  }

  void _updateFilter(AssetSearchFilter newFilter) {
    setState(() {
      _localFilter = newFilter;
    });
    widget.onFilterChanged(newFilter);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldOptionsBloc, FieldOptionsState>(
      builder: (context, state) {
        if (state is! FieldOptionsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final assetTypeOptions = state.getOptionsFor('asset_type');
        final cpuOptions = state.getOptionsFor('cpu');
        final generationOptions = state.getOptionsFor('generation');
        final ramTypeOptions = state.getOptionsFor('ram_ddr_type');
        final ramFormFactorOptions = state.getOptionsFor('ram_form_factor');
        final storageTypeOptions = state.getOptionsFor('storage_type');

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TEXT SEARCH SECTION
              _buildSectionHeader('Text Search', Icons.text_fields),
              const SizedBox(height: 8),
              TextField(
                controller: _tagIdController,
                decoration: const InputDecoration(
                  labelText: 'Tag ID',
                  hintText: 'Search by tag ID...',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateFilter(
                    _localFilter.copyWith(tagId: value.isEmpty ? null : value),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _serialNumberController,
                decoration: const InputDecoration(
                  labelText: 'Serial Number',
                  hintText: 'Search by serial number...',
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateFilter(
                    _localFilter.copyWith(
                      serialNumber: value.isEmpty ? null : value,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _modelNumberController,
                decoration: const InputDecoration(
                  labelText: 'Model Number',
                  hintText: 'Search by model number...',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateFilter(
                    _localFilter.copyWith(
                      modelNumber: value.isEmpty ? null : value,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // HARDWARE SECTION
              _buildSectionHeader('Hardware', Icons.computer),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MultiSelectFilter(
                    label: 'Asset Type',
                    options: assetTypeOptions,
                    selectedValues: _localFilter.assetTypes,
                    onChanged: (values) {
                      _updateFilter(_localFilter.copyWith(assetTypes: values));
                    },
                  ),
                  const SizedBox(height: 12),
                  MultiSelectFilter(
                    label: 'CPU',
                    options: cpuOptions,
                    selectedValues: _localFilter.cpus,
                    onChanged: (values) {
                      _updateFilter(_localFilter.copyWith(cpus: values));
                    },
                  ),
                  const SizedBox(height: 12),
                  MultiSelectFilter(
                    label: 'Generation',
                    options: generationOptions,
                    selectedValues: _localFilter.generations,
                    onChanged: (values) {
                      _updateFilter(_localFilter.copyWith(generations: values));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // RAM SECTION
              _buildSectionHeader('RAM', Icons.memory),
              const SizedBox(height: 8),
              SizeComparisonFilter(
                label: 'Total RAM Size',
                value: _localFilter.ramTotalSize,
                operator: _localFilter.ramSizeOperator ?? '>=',
                unit: 'GB',
                onChanged: (value, operator) {
                  _updateFilter(
                    _localFilter.copyWith(
                      ramTotalSize: value,
                      ramSizeOperator: operator,
                      clearRamSize: value == null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              MultiSelectFilter(
                label: 'RAM Type',
                options: ramTypeOptions,
                selectedValues: _localFilter.ramTypes,
                onChanged: (values) {
                  _updateFilter(_localFilter.copyWith(ramTypes: values));
                },
              ),
              const SizedBox(height: 12),
              MultiSelectFilter(
                label: 'RAM Form Factor',
                options: ramFormFactorOptions,
                selectedValues: _localFilter.ramFormFactors,
                onChanged: (values) {
                  _updateFilter(_localFilter.copyWith(ramFormFactors: values));
                },
              ),
              const SizedBox(height: 24),

              // STORAGE SECTION
              _buildSectionHeader('Storage', Icons.storage),
              const SizedBox(height: 8),
              SizeComparisonFilter(
                label: 'Total Storage Size',
                value: _localFilter.storageTotalSize,
                operator: _localFilter.storageSizeOperator ?? '>=',
                unit: 'GB',
                onChanged: (value, operator) {
                  _updateFilter(
                    _localFilter.copyWith(
                      storageTotalSize: value,
                      storageSizeOperator: operator,
                      clearStorageSize: value == null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              MultiSelectFilter(
                label: 'Storage Type',
                options: storageTypeOptions,
                selectedValues: _localFilter.storageTypes,
                onChanged: (values) {
                  _updateFilter(_localFilter.copyWith(storageTypes: values));
                },
              ),
              const SizedBox(height: 24),

              // LOCATION SECTION
              _buildSectionHeader('Location', Icons.location_on),
              const SizedBox(height: 8),
              BlocBuilder<LocationsBloc, LocationsState>(
                builder: (context, state) {
                  if (state is LocationsLoading || state is LocationsInitial) {
                    return const Text('Loading locations...');
                  }

                  final locations = switch (state) {
                    LocationsLoaded s => s.locationTree,
                    LocationActionInProgress s => s.locationTree,
                    LocationActionSuccess s => s.locationTree,
                    _ => <LocationModel>[],
                  };

                  if (locations.isEmpty) {
                    return const Text('No locations available');
                  }

                  return _buildLocationSelector(locations);
                },
              ),
              const SizedBox(height: 24),

              // SEARCH BUTTON
              FilledButton.icon(
                onPressed: widget.onSearch,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSelector(List<LocationModel> locations) {
    // Flatten locations for dropdown
    final allLocations = <LocationModel>[];
    void addWithChildren(LocationModel loc, int depth) {
      allLocations.add(loc);
      for (final child in loc.children) {
        addWithChildren(child, depth + 1);
      }
    }

    for (final loc in locations) {
      addWithChildren(loc, 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _localFilter.locationIds.isNotEmpty
              ? _localFilter.locationIds.first
              : null,
          decoration: const InputDecoration(
            labelText: 'Location',
            hintText: 'Select location...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Locations'),
            ),
            ...allLocations.map((loc) {
              final indent = '  ' * _getLocationDepth(loc, locations);
              return DropdownMenuItem<String>(
                value: loc.id,
                child: Text('$indent${loc.name}'),
              );
            }),
          ],
          onChanged: (value) {
            _updateFilter(
              _localFilter.copyWith(locationIds: value != null ? [value] : []),
            );
          },
        ),
        if (_localFilter.locationIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Includes all sub-locations',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }

  int _getLocationDepth(LocationModel target, List<LocationModel> roots) {
    int findDepth(LocationModel loc, int currentDepth) {
      if (loc.id == target.id) return currentDepth;
      for (final child in loc.children) {
        final depth = findDepth(child, currentDepth + 1);
        if (depth >= 0) return depth;
      }
      return -1;
    }

    for (final root in roots) {
      final depth = findDepth(root, 0);
      if (depth >= 0) return depth;
    }
    return 0;
  }
}
