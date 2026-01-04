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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
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

    final locations = _getLocations(state);
    final actionLocationId =
        state is LocationActionInProgress ? state.actionLocationId : null;

    if (locations.isEmpty) {
      return const Center(child: Text('No locations found'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<LocationsBloc>().add(LocationsFetchRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          final isLoading = actionLocationId == location.id;

          return ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(location.name),
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
                          _showLocationDialog(context, location: location);
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
        },
      ),
    );
  }

  List<LocationModel> _getLocations(LocationsState state) {
    return switch (state) {
      LocationsLoaded s => s.locations,
      LocationActionInProgress s => s.locations,
      LocationActionSuccess s => s.locations,
      _ => [],
    };
  }

  void _showLocationDialog(BuildContext context, {LocationModel? location}) {
    final isEditing = location != null;
    final nameController = TextEditingController(text: location?.name ?? '');
    final descriptionController =
        TextEditingController(text: location?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? 'Edit Location' : 'Add Location'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter location name',
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
                ),
                maxLines: 2,
              ),
            ],
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
                  context.read<LocationsBloc>().add(LocationUpdateRequested(
                        id: location.id,
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      ));
                } else {
                  context.read<LocationsBloc>().add(LocationCreateRequested(
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      ));
                }
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, LocationModel location) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text(
          'Are you sure you want to delete "${location.name}"?\n\n'
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
