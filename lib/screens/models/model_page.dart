import 'package:asset_manager/models/model.dart';
import 'package:asset_manager/screens/models/model_field_row.dart';
import 'package:asset_manager/services/database.dart';
import 'package:asset_manager/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

import '../../shared/constants.dart';

class ModelPage extends StatefulWidget {
  final Model? model;

  const ModelPage({super.key, this.model});

  @override
  State<ModelPage> createState() => _ModelPageState();
}

class _ModelPageState extends State<ModelPage> {
  String _id = "";
  Map<String, String> _fields = {};
  List<String> _fieldOrder = [];
  String _identifyingField = "";
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.model is Model) {
      _id = widget.model!.id;
      _identifyingField = widget.model!.identifyingField;
      _fieldOrder = widget.model!.fieldOrder.toList();
      _fields = Map.fromEntries(_fieldOrder
          .map((element) => MapEntry(element, widget.model!.fields[element]!)));
    } else {
      _fields = {"Name": "String"};
      _fieldOrder = ["Name"];
      _identifyingField = "Name";
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.model == null ? "New Model" : "Edit Model"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SpacedRow(
              widget1: Text("Model Id", style: font(22)),
              widget2: widget.model == null
                  ? SizedBox(
                      width: 50.w,
                      child: TextFormField(
                        controller: textController,
                        decoration: const InputDecoration(
                          labelText: "Can't be changed later",
                        ),
                        onSaved: (newValue) => _id = newValue!,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) =>
                            (value?.isEmpty ?? true) ? "Can't be empty" : null,
                      ),
                    )
                  : Text(widget.model!.id, style: font(22)),
            ),
            Card(
              margin: const EdgeInsets.fromLTRB(0.0, 6.0, 0.0, 0.0),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Fields",
                      style: font(25),
                    ),
                  ),
                  const Divider(thickness: 1),
                  ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }

                        final String item = _fieldOrder.removeAt(oldIndex);
                        _fieldOrder.insert(newIndex, item);
                      });
                    },
                    shrinkWrap: true,
                    children: _fieldsOptions(),
                  ),
                  SizedBox(height: 2.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      child: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          int count = 0;
                          for (var element in _fieldOrder) {
                            if (element.startsWith("New Field ")) count++;
                          }
                          _fields["New Field $count"] = "String";
                          _fieldOrder.add("New Field $count");
                        });
                      },
                    ),
                  ),
                ]),
              ),
            ),
            SizedBox(
              height: 2.w,
            ),
            SpacedRow(
              widget1: Text("Identifying Field", style: font(22)),
              widget2: DropdownButton(
                items: _fieldOrder
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                value: _identifyingField,
                onChanged: (value) {
                  setState(() {
                    _identifyingField = value!;
                  });
                },
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton.extended(
                heroTag: "save-fab",
                onPressed: () async {
                  if (widget.model is Model) {
                    Model model = widget.model!;

                    if (model.identifyingField == _identifyingField &&
                        const ListEquality()
                            .equals(model.fieldOrder, _fieldOrder) &&
                        const MapEquality().equals(model.fields, _fields)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("No changes made"),
                      ));
                      return;
                    }

                    await DatabaseService().updateModel(_id, {
                      "identifyingField": _identifyingField,
                      "fieldOrder": _fieldOrder,
                      "fields": _fields,
                    });
                  } else {
                    _id = textController.value.text;
                    if (_id.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Model Id can't be empty"),
                      ));
                      return;
                    }

                    await DatabaseService().createModel(_id, {
                      "identifyingField": _identifyingField,
                      "fieldOrder": _fieldOrder,
                      "fields": _fields,
                    });
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            widget.model == null ? "Created!" : "Updated!"),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                label: Text(
                  "Save",
                  style: font(22),
                ),
                icon: const Icon(Icons.save),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _fieldsOptions() {
    List<Widget> fields = [];

    for (var key in _fieldOrder) {
      String value = _fields[key]!;
      bool editable = false;
      if (widget.model == null) {
        editable = true;
      } else {
        editable = !widget.model!.fieldOrder.contains(key);
      }

      ModelFieldRow fieldRow = ModelFieldRow(
        key: Key("$key-$value"),
        fieldName: key,
        fieldType: value,
        editable: editable,
        onNameChange: (newName) {
          return newName == key || !_fields.containsKey(newName);
        },
        onNameSaved: (newName) {
          _fields[newName] = _fields.remove(key)!;
          _fieldOrder[_fieldOrder.indexOf(key)] = newName;
        },
        onTypeEdit: (newType) {
          setState(() {
            _fields[key] = newType!;
          });
        },
        onDelete: () {
          setState(() {
            _fieldOrder.remove(key);
            _fields.remove(key);
          });
        },
      );

      fields.add(fieldRow);
    }

    return fields;
  }
}
