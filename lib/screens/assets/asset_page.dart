import 'dart:collection';

import 'package:asset_manager/services/database.dart';
import 'package:asset_manager/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/asset.dart';
import '../../models/model.dart';
import '../../shared/constants.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

class AssetPage extends StatefulWidget {
  final Asset? asset;

  const AssetPage({super.key, this.asset});

  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  Model? _selectedModel;
  Map<String, dynamic> _fields = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    if (widget.asset != null) {
      _fields = Map.from(widget.asset!.fields);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var models = Provider.of<List<Model>>(context);
    List<DropdownMenuItem<Model>>? modelOptions = models
        .map((model) => DropdownMenuItem<Model>(
              value: model,
              child: Text(model.id),
            ))
        .toList();

    if (modelOptions.isEmpty || widget.asset != null) {
      modelOptions = null;
    }

    if (widget.asset != null) {
      _selectedModel = models
          .where(
            (element) => element.id == widget.asset!.type,
          )
          .toList()
          .first;
    }

    List<Widget> fields = getFields();

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.asset != null ? "Edit Asset" : "Create Asset"),
          actions: [
            if (widget.asset != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Delete Asset"),
                        content: const Text(
                            "Are you sure you want to delete this asset?"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              await DatabaseService()
                                  .deleteAsset(widget.asset!.id);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text("Delete"),
                          ),
                        ],
                      );
                    },
                  );
                },
              )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (widget.asset != null) ...[
                SpacedRow(
                  widget1: Text("Asset ID", style: font(22)),
                  widget2:
                      Expanded(child: Text(widget.asset!.id, style: font(22))),
                ),
                const SizedBox(height: 20)
              ],
              SpacedRow(
                  widget1: Text(
                    "Model Type",
                    style: font(22),
                  ),
                  widget2: SizedBox(
                    width: 50.w,
                    child: DropdownButton(
                      items: modelOptions,
                      isExpanded: true,
                      onChanged: (value) {
                        setState(() {
                          _selectedModel = value;
                        });
                      },
                      hint: Text(_selectedModel?.id ?? ""),
                      disabledHint: Text(widget.asset == null
                          ? "No models available"
                          : widget.asset!.type),
                    ),
                  )),
              if (fields.isNotEmpty)
                Card(
                  margin: const EdgeInsets.fromLTRB(0.0, 6.0, 0, 0.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Fields",
                            style: font(25),
                          ),
                        ),
                        const Divider(thickness: 1),
                        ...fields,
                      ]),
                    ),
                  ),
                ),
              SizedBox(
                height: 2.w,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomCenter,
                child: FloatingActionButton.extended(
                  onPressed: _selectedModel == null
                      ? null
                      : () async {
                          // Validate fields
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }
                          _formKey.currentState!.save();

                          if (!Set.from(_fields.keys).containsAll(
                              Set.from(_selectedModel!.fieldOrder))) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Fill in all fields"),
                              ),
                            );
                            return;
                          }

                          if (widget.asset is Asset) {
                            if (const MapEquality()
                                .equals(_fields, widget.asset!.fields)) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text("No changes made"),
                              ));
                              return;
                            }

                            // Update asset
                            await DatabaseService().updateAsset(
                              widget.asset!.id,
                              {
                                "fields": _fields,
                              },
                            );
                          } else {
                            // Create asset
                            await DatabaseService().createAsset(
                              {
                                "fields": _fields,
                                "type": _selectedModel!.id,
                              },
                            );
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(widget.asset == null
                                    ? "Created!"
                                    : "Updated!"),
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
        ));
  }

  List<Widget> getFields() {
    List<Widget> fields = [];

    if (_selectedModel is Model) {
      for (var key in _selectedModel!.fieldOrder) {
        Widget fieldValueWidget = const Text("No widget available");
        var value = _selectedModel!.fields[key]!;
        switch (value) {
          case "String":
            fieldValueWidget = SizedBox(
              width: 40.w, // 40% of screen width
              child: TextFormField(
                initialValue: widget.asset?.fields[key]! ?? "",
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSaved: (newValue) => _fields[key] = newValue,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "This field is required";
                  }
                  return null;
                },
              ),
            );
            break;
          case "Number":
            fieldValueWidget = SizedBox(
              width: 40.w, // 40% of screen width
              child: TextFormField(
                initialValue: widget.asset?.fields[key]!.toString() ?? "",
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSaved: (newValue) => _fields[key] = double.parse(newValue!),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "This field is required";
                  }

                  if (double.tryParse(value) == null) {
                    return "This field must be a number";
                  }

                  return null;
                },
              ),
            );
            break;
          case "Boolean":
            if (!_fields.containsKey(key)) {
              _fields[key] = widget.asset?.fields[key] ?? false;
            }
            fieldValueWidget = Checkbox(
              value: _fields[key]!,
              onChanged: (value) {
                setState(() {
                  _fields[key] = value!;
                });
              },
            );
            break;
          case "DateTime":
            fieldValueWidget = TextButton(
              onPressed: () async {
                var date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );

                TimeOfDay? time;
                if (context.mounted) {
                  time = await showTimePicker(
                    initialTime: TimeOfDay.now(),
                    context: context,
                  );
                } else {
                  return;
                }

                if (date != null && time != null) {
                  setState(() {
                    _fields[key] = (DateTime(date.year, date.month, date.day,
                                time!.hour, time.minute))
                            .millisecondsSinceEpoch ~/
                        1000;
                  });
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Date and Time not selected"),
                      ),
                    );
                  }
                }
              },
              child: _fields[key] == null
                  ? const Text("Select date and time")
                  : Text(DateFormat('yyyy-MM-dd H:m').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          _fields[key]! * 1000))),
            );
        }

        fields.addAll([
          SpacedRow(
            widget1: Text(key, style: font(16)),
            widget2: fieldValueWidget,
          ),
          const SizedBox(height: 10)
        ]);
      }
    }
    return fields;
  }
}
