import 'package:flutter/material.dart';

import '../../data/models/ram_module_model.dart';

class RamModuleEditor extends StatelessWidget {
  final List<RamModuleModel> modules;
  final ValueChanged<List<RamModuleModel>> onChanged;
  final List<String> sizeOptions;
  final List<String> formFactorOptions;
  final List<String> ddrTypeOptions;

  const RamModuleEditor({
    super.key,
    required this.modules,
    required this.onChanged,
    required this.sizeOptions,
    required this.formFactorOptions,
    required this.ddrTypeOptions,
  });

  void _addModule() {
    onChanged([...modules, const RamModuleModel()]);
  }

  void _updateModule(int index, RamModuleModel module) {
    final updated = List<RamModuleModel>.from(modules);
    updated[index] = module;
    onChanged(updated);
  }

  void _removeModule(int index) {
    final updated = List<RamModuleModel>.from(modules);
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
            Icon(Icons.memory, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('RAM Modules', style: theme.textTheme.titleMedium),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: _addModule,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (modules.isEmpty)
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
                  'No RAM modules added',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          )
        else
          ...modules.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RamModuleCard(
              module: entry.value,
              index: entry.key,
              sizeOptions: sizeOptions,
              formFactorOptions: formFactorOptions,
              ddrTypeOptions: ddrTypeOptions,
              onUpdate: (updated) => _updateModule(entry.key, updated),
              onRemove: () => _removeModule(entry.key),
            ),
          )),
      ],
    );
  }
}

class _RamModuleCard extends StatelessWidget {
  final RamModuleModel module;
  final int index;
  final List<String> sizeOptions;
  final List<String> formFactorOptions;
  final List<String> ddrTypeOptions;
  final ValueChanged<RamModuleModel> onUpdate;
  final VoidCallback onRemove;

  const _RamModuleCard({
    required this.module,
    required this.index,
    required this.sizeOptions,
    required this.formFactorOptions,
    required this.ddrTypeOptions,
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
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'RAM ${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
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
                    value: module.size,
                    options: sizeOptions,
                    onChanged: (v) => onUpdate(module.copyWith(size: v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    context: context,
                    label: 'DDR Type',
                    value: module.ddrType,
                    options: ddrTypeOptions,
                    onChanged: (v) => onUpdate(module.copyWith(ddrType: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              context: context,
              label: 'Form Factor',
              value: module.formFactor,
              options: formFactorOptions,
              onChanged: (v) => onUpdate(module.copyWith(formFactor: v)),
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
