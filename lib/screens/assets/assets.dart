import 'package:flutter/material.dart';
import '../../models/asset.dart';
import 'package:provider/provider.dart';

import 'asset_tile.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  @override
  Widget build(BuildContext context) {
    final assets = Provider.of<List<Asset>>(context);
    return ListView.builder(
      itemCount: assets.length,
      itemBuilder: (context, index) {
        return AssetTile(asset: assets[index]);
      },
    );
  }
}
