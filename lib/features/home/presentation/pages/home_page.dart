import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../profile/bloc/profile_bloc.dart';
import '../../../profile/bloc/profile_state.dart';

class HomePage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomePage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        final isAdmin =
            profileState is ProfileLoaded && profileState.profile.isAdmin;

        // Map shell index to display index (accounting for hidden Users tab)
        final displayIndex = _shellIndexToDisplayIndex(
          navigationShell.currentIndex,
          isAdmin,
        );

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: displayIndex,
            onDestinationSelected: (index) {
              final shellIndex = _displayIndexToShellIndex(index, isAdmin);
              navigationShell.goBranch(
                shellIndex,
                initialLocation: shellIndex == navigationShell.currentIndex,
              );
            },
            destinations: _buildDestinations(isAdmin),
          ),
        );
      },
    );
  }

  int _shellIndexToDisplayIndex(int shellIndex, bool isAdmin) {
    // Shell branches: 0=Assets, 1=Users, 2=Settings
    // Display for admin: 0=Assets, 1=Users, 2=Settings
    // Display for non-admin: 0=Assets, 1=Settings (Users hidden)
    if (isAdmin) return shellIndex;
    // Non-admin: Settings (shell 2) becomes display 1
    return shellIndex == 2 ? 1 : shellIndex;
  }

  int _displayIndexToShellIndex(int displayIndex, bool isAdmin) {
    if (isAdmin) return displayIndex;
    // Non-admin: display 1 (Settings) maps to shell 2
    return displayIndex == 1 ? 2 : displayIndex;
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
}
