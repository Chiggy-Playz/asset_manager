import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/location_model.dart';
import '../../bloc/locations_bloc.dart';
import '../../bloc/locations_event.dart';
import '../../bloc/locations_state.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    context.read<LocationsBloc>().add(LocationsFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationsBloc, LocationsState>(
      listener: (context, state) {
        if (state is LocationActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is LocationsError) {
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
          appBar: AppBar(title: const Text('Locations')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showLocationDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Location'),
          ),
          body: ResponsiveBuilder(
            builder: (context, screenSize) {
              final content = _buildContent(context, state);
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
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, LocationsState state) {
    if (state is LocationsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tree = _getLocationTree(state);
    final flatLocations = _getLocations(state);
    final actionLocationId = state is LocationActionInProgress
        ? state.actionLocationId
        : null;

    if (tree.isEmpty) {
      return const Center(child: Text('No locations found'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<LocationsBloc>().add(LocationsFetchRequested());
      },
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        children: tree
            .map(
              (location) => _buildLocationTile(
                context,
                location,
                flatLocations,
                actionLocationId,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLocationTile(
    BuildContext context,
    LocationModel location,
    List<LocationModel> flatLocations,
    String? actionLocationId,
  ) {
    final isLoading = actionLocationId == location.id;
    final hasChildren = location.children.isNotEmpty;
    final isExpanded = _expandedIds.contains(location.id);
    final theme = Theme.of(context);

    final levelLabels = ['', 'L2', 'L3'];
    final levelLabel = location.level < levelLabels.length
        ? levelLabels[location.level]
        : 'L${location.level + 1}';

    final tile = ListTile(
      onTap: hasChildren
          ? () {
              setState(() {
                if (isExpanded) {
                  _expandedIds.remove(location.id);
                } else {
                  _expandedIds.add(location.id);
                }
              });
            }
          : null,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasChildren)
            IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  if (isExpanded) {
                    _expandedIds.remove(location.id);
                  } else {
                    _expandedIds.add(location.id);
                  }
                });
              },
            )
          else
            const SizedBox(width: 48),
          Icon(
            location.level == 0
                ? Icons.location_city
                : location.level == 1
                ? Icons.layers
                : Icons.room,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(child: Text(location.name)),
          if (location.level > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                levelLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
        ],
      ),
      subtitle: location.description != null
          ? Text(location.description!)
          : null,
      trailing: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showLocationDialog(
                      context,
                      location: location,
                      flatLocations: flatLocations,
                    );
                  case 'add_child':
                    _showLocationDialog(
                      context,
                      parentLocation: location,
                      flatLocations: flatLocations,
                    );
                  case 'delete':
                    _showDeleteConfirmation(context, location);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                if (location.canHaveChildren)
                  const PopupMenuItem(
                    value: 'add_child',
                    child: Row(
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text('Add Sub-location'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
    );

    if (!hasChildren || !isExpanded) {
      return tile;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: location.children
                .map(
                  (child) => _buildLocationTile(
                    context,
                    child,
                    flatLocations,
                    actionLocationId,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  List<LocationModel> _getLocationTree(LocationsState state) {
    return switch (state) {
      LocationsLoaded s => s.locationTree,
      LocationActionInProgress s => s.locationTree,
      LocationActionSuccess s => s.locationTree,
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

  void _showLocationDialog(
    BuildContext context, {
    LocationModel? location,
    LocationModel? parentLocation,
    List<LocationModel>? flatLocations,
  }) {
    final isEditing = location != null;
    final nameController = TextEditingController(text: location?.name ?? '');
    final descriptionController = TextEditingController(
      text: location?.description ?? '',
    );
    final formKey = GlobalKey<FormState>();

    // For new locations, use parentLocation if provided, otherwise null
    // For editing, use the location's current parent
    String? selectedParentId = isEditing
        ? location.parentId
        : parentLocation?.id;

    final state = context.read<LocationsBloc>().state;
    final allLocations = flatLocations ?? _getLocations(state);

    // Get available parents (exclude self and descendants when editing)
    final availableParents = allLocations.where((l) {
      // Can't be its own parent
      if (isEditing && l.id == location.id) return false;
      // Can't select a descendant as parent (would create cycle)
      if (isEditing && l.isDescendantOf(location.id, allLocations))
        return false;
      // Can only have up to 3 levels
      if (l.level >= 2) return false;
      return true;
    }).toList();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isEditing
                  ? 'Edit Location'
                  : parentLocation != null
                  ? 'Add Sub-location to ${parentLocation.name}'
                  : 'Add Location',
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter location name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Enter description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: selectedParentId,
                      decoration: const InputDecoration(
                        labelText: 'Parent Location (optional)',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None (Top Level)'),
                        ),
                        ...availableParents.map((parent) {
                          final indent = '  ' * parent.level;
                          return DropdownMenuItem<String?>(
                            value: parent.id,
                            child: Text('$indent${parent.name}'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedParentId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(dialogContext).pop();
                    if (isEditing) {
                      this.context.read<LocationsBloc>().add(
                        LocationUpdateRequested(
                          id: location.id,
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          parentId: selectedParentId,
                        ),
                      );
                    } else {
                      this.context.read<LocationsBloc>().add(
                        LocationCreateRequested(
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          parentId: selectedParentId,
                        ),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Update' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, LocationModel location) {
    final hasChildren = location.children.isNotEmpty;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text(
          hasChildren
              ? 'Are you sure you want to delete "${location.name}" and all its sub-locations?\n\n'
                    'Note: This will fail if any assets are currently at this location or its sub-locations.'
              : 'Are you sure you want to delete "${location.name}"?\n\n'
                    'Note: This will fail if any assets are currently at this location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<LocationsBloc>().add(
                LocationDeleteRequested(location.id),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
