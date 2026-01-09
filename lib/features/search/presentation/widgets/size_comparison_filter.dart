import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A filter widget for comparing sizes with operators.
class SizeComparisonFilter extends StatefulWidget {
  final String label;
  final int? value;
  final String operator;
  final String unit;
  final void Function(int? value, String operator) onChanged;

  const SizeComparisonFilter({
    super.key,
    required this.label,
    required this.value,
    required this.operator,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<SizeComparisonFilter> createState() => _SizeComparisonFilterState();
}

class _SizeComparisonFilterState extends State<SizeComparisonFilter> {
  late TextEditingController _valueController;
  late String _selectedOperator;

  static const operators = ['>', '<', '>=', '<=', '='];
  static const operatorLabels = {
    '>': 'Greater than',
    '<': 'Less than',
    '>=': 'At least',
    '<=': 'At most',
    '=': 'Exactly',
  };

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.value?.toString() ?? '',
    );
    _selectedOperator = widget.operator;
  }

  @override
  void didUpdateWidget(SizeComparisonFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _valueController.text = widget.value?.toString() ?? '';
    }
    if (widget.operator != oldWidget.operator) {
      _selectedOperator = widget.operator;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final text = _valueController.text.trim();
    final value = text.isEmpty ? null : int.tryParse(text);
    widget.onChanged(value, _selectedOperator);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Operator dropdown
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
                value: _selectedOperator,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: operators.map((op) {
                  return DropdownMenuItem<String>(
                    value: op,
                    child: Text(op),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedOperator = value;
                    });
                    _notifyChange();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            // Value input
            Expanded(
              child: TextField(
                controller: _valueController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Enter value...',
                  suffixText: widget.unit,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (_) => _notifyChange(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          operatorLabels[_selectedOperator] ?? _selectedOperator,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
