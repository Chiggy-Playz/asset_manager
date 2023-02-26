import 'package:asset_manager/shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

typedef VoidCallback = void Function();
typedef BoolTCallback<T> = bool Function(T value);
typedef VoidTCallback<T> = void Function(T value);

class ModelFieldRow extends StatefulWidget {
  String fieldName;
  String fieldType;

  /// Whether the field type is editable or not (this is not possible for existing models)
  bool editable;

  /// Callback that receives value when the field name is changed.
  /// Return true if the name is valid, false otherwise.
  /// Returning false indicates that field name already exists.
  BoolTCallback<String> onNameChange;

  /// Callback that receives value when the field name is saved
  VoidTCallback<String> onNameSaved;

  /// Callback that receives value when the field type is changed
  VoidTCallback<String?> onTypeEdit;

  /// Callback that is called when the delete button is pressed
  VoidCallback onDelete;

  ModelFieldRow({
    super.key,
    required this.fieldName,
    required this.fieldType,
    required this.editable,
    required this.onNameChange,
    required this.onNameSaved,
    required this.onTypeEdit,
    required this.onDelete,
  });

  @override
  State<ModelFieldRow> createState() => _ModelFieldRowState();
}

class _ModelFieldRowState extends State<ModelFieldRow> {
  bool _editing = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<String>> items =
        ["String", "Number", "Boolean", "DateTime"]
            .map((fieldType) => DropdownMenuItem<String>(
                  value: fieldType,
                  child: Text(fieldType),
                ))
            .toList();

    return Row(
      children: [
        _editing
            ? getFieldNameWidget()
            : Expanded(child: Text(widget.fieldName, style: font(18))),
        const SizedBox(width: 10),
        if (!_editing)
          DropdownButton<String>(
            items: items,
            onChanged: widget.editable
                ? (value) {
                    setState(() {
                      widget.fieldType = value!;
                    });
                    widget.onTypeEdit(value);
                  }
                : null,
            disabledHint: Text(widget.fieldType),
            hint: Text(widget.fieldType),
          ),
        if (_editing) const Spacer(),
        AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
            child: getIcon()),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: widget.onDelete,
        ),
      ],
    );
  }

  Widget getFieldNameWidget() {
    return SizedBox(
      width: 40.w,
      child: Form(
        key: _formKey,
        child: TextFormField(
          initialValue: widget.fieldName,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onSaved: (value) => widget.fieldName = value!,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return "Field name cannot be empty";
            }
            if (!widget.onNameChange(value!)) {
              return "Field name already exists";
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget getIcon() {
    return !_editing
        ? IconButton(
            key: const Key("edit"),
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _editing = true;
              });
            },
          )
        : IconButton(
            key: const Key("save"),
            icon: const Icon(Icons.save),
            onPressed: () {
              final FormState form = _formKey.currentState!;
              if (form.validate()) {
                form.save();
                setState(() {
                  _editing = false;
                });
                widget.onNameSaved(widget.fieldName);
              }
            },
          );
  }
}
