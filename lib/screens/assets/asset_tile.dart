import 'package:flutter/material.dart';
import '../../models/asset.dart';
import 'asset_page.dart';

class AssetTile extends StatelessWidget {
  final Asset asset;

  const AssetTile({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        margin: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 0.0),
        child: ListTile(
          title: Text(asset.id),
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
