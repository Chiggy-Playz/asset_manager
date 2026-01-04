import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../data/models/field_option_model.dart';
import '../../bloc/field_options_bloc.dart';
import '../../bloc/field_options_event.dart';
import '../../bloc/field_options_state.dart';

class FieldOptionsPage extends StatefulWidget {
  const FieldOptionsPage({super.key});

  @override
  State<FieldOptionsPage> createState() => _FieldOptionsPageState();
}

class _FieldOptionsPageState extends State<FieldOptionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<FieldOptionsBloc>().add(FieldOptionsFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Options'),
      ),
      body: BlocConsumer<FieldOptionsBloc, FieldOptionsState>(
        listener: (context, state) {
          if (state is FieldOptionActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is FieldOptionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FieldOptionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final fieldOptions = switch (state) {
            FieldOptionsLoaded s => s.fieldOptions,
            FieldOptionActionInProgress s => s.fieldOptions,
            FieldOptionActionSuccess s => s.fieldOptions,
            _ => <FieldOptionModel>[],
          };

          if (fieldOptions.isEmpty) {
            return const Center(child: Text('No field options configured'));
          }

          return ResponsiveBuilder(
            builder: (context, screenSize) {
              final content = ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: fieldOptions.length,
                itemBuilder: (context, index) {
                  final field = fieldOptions[index];
                  return _FieldOptionCard(
                    field: field,
                    onEdit: () => _showEditDialog(context, field),
                  );
                },
              );

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
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, FieldOptionModel field) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditFieldOptionsDialog(
        field: field,
        onSave: (options, isRequired) {
          context.read<FieldOptionsBloc>().add(FieldOptionUpdateRequested(
                fieldName: field.fieldName,
                options: options,
                isRequired: isRequired,
              ));
        },
      ),
    );
  }
}

class _FieldOptionCard extends StatelessWidget {
  final FieldOptionModel field;
  final VoidCallback onEdit;

  const _FieldOptionCard({
    required this.field,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    field.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (field.isRequired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Required',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit,
                    size: 20,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (field.options.isEmpty)
                Text(
                  'No options configured',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: field.options
                      .map((opt) => Chip(
                            label: Text(opt),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditFieldOptionsDialog extends StatefulWidget {
  final FieldOptionModel field;
  final void Function(List<String> options, bool isRequired) onSave;

  const _EditFieldOptionsDialog({
    required this.field,
    required this.onSave,
  });

  @override
  State<_EditFieldOptionsDialog> createState() =>
      _EditFieldOptionsDialogState();
}

class _EditFieldOptionsDialogState extends State<_EditFieldOptionsDialog> {
  late List<String> _options;
  late bool _isRequired;
  final _newOptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _options = List.from(widget.field.options);
    _isRequired = widget.field.isRequired;
  }

  @override
  void dispose() {
    _newOptionController.dispose();
    super.dispose();
  }

  void _addOption() {
    final value = _newOptionController.text.trim();
    if (value.isNotEmpty && !_options.contains(value)) {
      setState(() {
        _options.add(value);
        _newOptionController.clear();
      });
    }
  }

  void _removeOption(String option) {
    setState(() {
      _options.remove(option);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.field.displayName} Options'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Required toggle
              SwitchListTile(
                title: const Text('Required field'),
                value: _isRequired,
                onChanged: (value) => setState(() => _isRequired = value),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Add new option
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newOptionController,
                      decoration: const InputDecoration(
                        labelText: 'New option',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addOption(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current options
              const Text(
                'Current Options:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              if (_options.isEmpty)
                const Text(
                  'No options added yet',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _options
                      .map((opt) => Chip(
                            label: Text(opt),
                            onDeleted: () => _removeOption(opt),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_options, _isRequired);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
