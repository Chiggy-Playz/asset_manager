import 'package:asset_manager/models/asset.dart';
import 'package:asset_manager/screens/assets/assets_page.dart';
import 'package:asset_manager/screens/models/models_page.dart';
import 'package:asset_manager/services/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/model.dart';
import '../assets/asset_page.dart';
import '../models/model_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = const <Widget>[
    AssetsPage(),
    ModelsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Asset Manager'),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.laptop),
              label: 'Assets',
              tooltip: 'All assets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.model_training),
              label: 'Models',
              tooltip: 'All models',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: (value) => setState(() => _selectedIndex = value),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            switch (_selectedIndex) {
              case 0:
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AssetPage(),
                  ),
                );
                break;
              case 1:
              Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ModelPage(),
                  ),
                );
                break;
            }
          },
          tooltip: 'Create new',
          child: const Icon(Icons.add),
        ),
        body: _widgetOptions.elementAt(_selectedIndex));
  }
}
