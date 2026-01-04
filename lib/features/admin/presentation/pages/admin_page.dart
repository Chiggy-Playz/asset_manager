import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/routes.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Users'),
            subtitle: const Text('Manage user accounts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.adminUsers),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Locations'),
            subtitle: const Text('Manage asset locations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.adminLocations),
          ),
        ],
      ),
    );
  }
}
