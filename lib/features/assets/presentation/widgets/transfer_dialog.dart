import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/location_selector.dart';
import '../../../../data/models/location_model.dart';
import '../../../admin/bloc/locations_bloc.dart';
import '../../../admin/bloc/locations_event.dart';
import '../../../admin/bloc/locations_state.dart';

class TransferDialog extends StatefulWidget {
  final String? currentLocationId;
  final void Function(String locationId) onTransfer;

  const TransferDialog({
    super.key,
    this.currentLocationId,
    required this.onTransfer,
  });

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    context.read<LocationsBloc>().add(LocationsFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transfer Asset'),
      content: BlocBuilder<LocationsBloc, LocationsState>(
        builder: (context, state) {
          if (state is LocationsLoading) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is LocationsError) {
            return Text('Error: ${state.message}');
          }

          final locations = switch (state) {
            LocationsLoaded s => s.locations,
            LocationActionInProgress s => s.locations,
            LocationActionSuccess s => s.locations,
            _ => <LocationModel>[],
          };

          if (locations.isEmpty) {
            return const Text('No locations available');
          }

          return SizedBox(
            width: double.maxFinite,
            child: LocationSelector(
              locations: locations,
              selectedLocationId: _selectedLocationId,
              onChanged: (value) {
                setState(() {
                  _selectedLocationId = value;
                });
              },
              label: 'Select Location',
              isRequired: true,
              excludeIds: widget.currentLocationId != null
                  ? {widget.currentLocationId!}
                  : {},
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedLocationId == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  widget.onTransfer(_selectedLocationId!);
                },
          child: const Text('Transfer'),
        ),
      ],
    );
  }
}
