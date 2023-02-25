import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/model.dart';
import 'model_tile.dart';

class ModelsPage extends StatefulWidget {
  const ModelsPage({super.key});

  @override
  State<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage> {
  @override
  Widget build(BuildContext context) {
    final models = Provider.of<List<Model>>(context);
    return ListView.builder(
      itemCount: models.length,
      itemBuilder: (context, index) {
        return ModelTile(model: models[index]);
      },
    );
  }
}
