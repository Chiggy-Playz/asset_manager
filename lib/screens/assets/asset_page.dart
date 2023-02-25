import 'package:asset_manager/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/asset.dart';
import '../../models/model.dart';
import '../../shared/constants.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class AssetPage extends StatefulWidget {
  final Asset? asset;

  const AssetPage({super.key, this.asset});

  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  Model? _selectedModel;

  @override
  Widget build(BuildContext context) {
    var models = Provider.of<List<Model>>(context);
    List<DropdownMenuItem>? modelOptions = models
        .map((model) => DropdownMenuItem<Model>(
              value: model,
              child: Text(model.id),
            ))
        .toList();

    if (modelOptions.isEmpty || widget.asset != null) {
      modelOptions = null;
    }

    List<Widget> fieldsOptions = [];

    if (_selectedModel is Model) {
      _selectedModel!.fields.forEach((key, value) {
        Widget fieldValueWidget = const Text("No widget available");

        switch (value) {
          case "String":
            fieldValueWidget = SizedBox(
              width: 40.w, // 40% of screen width
              child: TextField(),
            );
            break;
          case "Number":
            fieldValueWidget = SizedBox(
              width: 40.w, // 40% of screen width
              child: TextField(),
            );
            break;
          case "Boolean":
            fieldValueWidget = Checkbox(
              value: false,
              onChanged: (value) {},
            );
            break;
          case "Date":
            fieldValueWidget = TextButton(
              onPressed: () async {
                var date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  print(date);
                }
              },
              child: const Text("Select date"),
            );
        }

        fieldsOptions.addAll([
          SpacedRow(
            widget1: Text(key, style: font(16)),
            widget2: fieldValueWidget,
          ),
          const SizedBox(height: 10)
        ]);
      });
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.asset != null ? "Edit Asset" : "Create Asset"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (widget.asset != null) ...[
                SpacedRow(
                  widget1: Text("Asset ID", style: font(22)),
                  widget2: Text(widget.asset!.id, style: font(22)),
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
                          _selectedModel = value as Model?;
                        });
                      },
                      disabledHint: Text(widget.asset == null
                          ? "No models available"
                          : "Cannot change model type"),
                    ),
                  )),
              if (fieldsOptions.isNotEmpty)
                Card(
                  margin: const EdgeInsets.fromLTRB(0.0, 6.0, 0, 0.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(children: fieldsOptions),
                  ),
                )
            ],
          ),
        ));
  }
}
