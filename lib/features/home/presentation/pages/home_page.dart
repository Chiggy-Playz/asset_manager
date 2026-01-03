import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../assets/presentation/pages/assets_page.dart';
import '../../../profile/bloc/profile_bloc.dart';
import '../../../profile/bloc/profile_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../users/presentation/pages/users_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        final isAdmin = profileState is ProfileLoaded && profileState.profile.isAdmin;
        final destinations = _buildDestinations(isAdmin);
        final pages = _buildPages(isAdmin);

        // Ensure index is valid if admin status changes
        if (_currentIndex >= pages.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: destinations,
          ),
        );
      },
    );
  }

  List<NavigationDestination> _buildDestinations(bool isAdmin) {
    return [
      const NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Assets',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Users',
        ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
  }

  List<Widget> _buildPages(bool isAdmin) {
    return [
      const AssetsPage(),
      if (isAdmin) const UsersPage(),
      const SettingsPage(),
    ];
  }
}
