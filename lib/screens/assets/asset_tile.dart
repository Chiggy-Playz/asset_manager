import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/asset.dart';
import '../../models/model.dart';
import 'asset_page.dart';

class AssetTile extends StatelessWidget {
  final Asset asset;

  const AssetTile({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    Model model = Provider.of<List<Model>>(context)
        .firstWhere((element) => element.id == asset.type);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        margin: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 0.0),
        child: ListTile(
          title: Text(asset.fields[model.identifyingField]),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return AssetPage(asset: asset);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
