import 'package:flutter/material.dart';
import '../../models/model.dart';
import 'model_page.dart';

class ModelTile extends StatelessWidget {
  final Model model;

  const ModelTile({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        margin: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 0.0),
        child: ListTile(
          title: Text(model.id),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return ModelPage(model: model);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
