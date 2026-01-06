import 'package:flutter/material.dart';

import '../../data/models/storage_device_model.dart';

class StorageDeviceEditor extends StatelessWidget {
  final List<StorageDeviceModel> devices;
  final ValueChanged<List<StorageDeviceModel>> onChanged;
  final List<String> sizeOptions;
  final List<String> typeOptions;

  const StorageDeviceEditor({
    super.key,
    required this.devices,
    required this.onChanged,
    required this.sizeOptions,
    required this.typeOptions,
  });

  void _addDevice() {
    onChanged([...devices, const StorageDeviceModel()]);
  }

  void _updateDevice(int index, StorageDeviceModel device) {
    final updated = List<StorageDeviceModel>.from(devices);
    updated[index] = device;
    onChanged(updated);
  }

  void _removeDevice(int index) {
    final updated = List<StorageDeviceModel>.from(devices);
    updated.removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sd_storage, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Storage Devices', style: theme.textTheme.titleMedium),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: _addDevice,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (devices.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.outline, size: 18),
                const SizedBox(width: 8),
                Text(
                  'No storage devices added',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          )
        else
          ...devices.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StorageDeviceCard(
              device: entry.value,
              index: entry.key,
              sizeOptions: sizeOptions,
              typeOptions: typeOptions,
              onUpdate: (updated) => _updateDevice(entry.key, updated),
              onRemove: () => _removeDevice(entry.key),
            ),
          )),
      ],
    );
  }
}

class _StorageDeviceCard extends StatelessWidget {
  final StorageDeviceModel device;
  final int index;
  final List<String> sizeOptions;
  final List<String> typeOptions;
  final ValueChanged<StorageDeviceModel> onUpdate;
  final VoidCallback onRemove;

  const _StorageDeviceCard({
    required this.device,
    required this.index,
    required this.sizeOptions,
    required this.typeOptions,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Storage ${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  color: theme.colorScheme.error,
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    context: context,
                    label: 'Size',
                    value: device.size,
                    options: sizeOptions,
                    onChanged: (v) => onUpdate(device.copyWith(size: v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    context: context,
                    label: 'Type',
                    value: device.type,
                    options: typeOptions,
                    onChanged: (v) => onUpdate(device.copyWith(type: v)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    if (options.isEmpty) {
      return TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          helperText: 'No options configured',
        ),
        onChanged: onChanged,
      );
    }

    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Select...')),
        ...options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))),
      ],
      onChanged: onChanged,
    );
  }
}
