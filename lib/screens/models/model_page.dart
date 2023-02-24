import 'package:asset_manager/models/model.dart';
import 'package:flutter/material.dart';

import '../../shared/constants.dart';

class ModelPage extends StatefulWidget {
  final Model? model;

  const ModelPage({super.key, this.model});

  @override
  State<ModelPage> createState() => _ModelPageState();
}

class _ModelPageState extends State<ModelPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.model != null ? "New Model" : "Edit Model"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Model ID", style: font(22)),
                ]
              )
          ],
        ),
      ),
    );
  }
}
