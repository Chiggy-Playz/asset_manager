import 'package:flutter/material.dart';

import '../../data/models/location_model.dart';

/// A hierarchical location selector widget that displays locations
/// in a tree-like dropdown with indentation.
class LocationSelector extends StatelessWidget {
  /// Flat list of all locations with levels set
  final List<LocationModel> locations;

  /// Currently selected location ID
  final String? selectedLocationId;

  /// Callback when a location is selected
  final ValueChanged<String?> onChanged;

  /// Label for the field
  final String label;

  /// Whether the field is required
  final bool isRequired;

  /// Whether the field is enabled
  final bool enabled;

  /// Location IDs to exclude from the dropdown (e.g., current location in transfer)
  final Set<String> excludeIds;

  /// Whether to also exclude descendants of excluded IDs
  final bool excludeDescendants;

  const LocationSelector({
    super.key,
    required this.locations,
    required this.selectedLocationId,
    required this.onChanged,
    this.label = 'Location',
    this.isRequired = false,
    this.enabled = true,
    this.excludeIds = const {},
    this.excludeDescendants = false,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out excluded locations
    final availableLocations = _getAvailableLocations();

    if (availableLocations.isEmpty && !isRequired) {
      return TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          hintText: 'No locations available',
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: availableLocations.any((l) => l.id == selectedLocationId)
          ? selectedLocationId
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      items: [
        if (!isRequired)
          const DropdownMenuItem<String>(value: null, child: Text('None')),
        ...availableLocations.map((location) {
          return DropdownMenuItem<String>(
            value: location.id,
            child: _LocationItem(location: location, allLocations: locations),
          );
        }),
      ],
      onChanged: enabled ? onChanged : null,
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a location';
              }
              return null;
            }
          : null,
      selectedItemBuilder: (context) {
        return [
          if (!isRequired) const Text('None'),
          ...availableLocations.map((location) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                location.getFullPath(locations),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ];
      },
    );
  }

  List<LocationModel> _getAvailableLocations() {
    if (excludeIds.isEmpty) {
      return locations;
    }

    return locations.where((location) {
      // Check if this location is directly excluded
      if (excludeIds.contains(location.id)) {
        return false;
      }

      // Check if we should exclude descendants
      if (excludeDescendants) {
        for (final excludeId in excludeIds) {
          if (location.isDescendantOf(excludeId, locations)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }
}

class _LocationItem extends StatelessWidget {
  final LocationModel location;
  final List<LocationModel> allLocations;

  const _LocationItem({required this.location, required this.allLocations});

  @override
  Widget build(BuildContext context) {
    final indent = location.level * 16.0;

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Row(
        children: [
          if (location.level > 0) ...[
            Icon(
              Icons.subdirectory_arrow_right,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(child: Text(location.name, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
