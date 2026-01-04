import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive.dart';
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

        // Map shell index to display index
        final displayIndex = _shellIndexToDisplayIndex(
          navigationShell.currentIndex,
          isAdmin,
        );

        return ResponsiveBuilder(
          builder: (context, screenSize) {
            final isMobile = screenSize == ScreenSize.mobile;

            if (isMobile) {
              return Scaffold(
                body: navigationShell,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: displayIndex,
                  onDestinationSelected: (index) => _onDestinationSelected(
                    index,
                    isAdmin,
                  ),
                  destinations: _buildBarDestinations(isAdmin),
                ),
              );
            }

            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: displayIndex,
                    onDestinationSelected: (index) => _onDestinationSelected(
                      index,
                      isAdmin,
                    ),
                    labelType: NavigationRailLabelType.all,
                    destinations: _buildRailDestinations(isAdmin),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: navigationShell),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onDestinationSelected(int index, bool isAdmin) {
    final shellIndex = _displayIndexToShellIndex(index, isAdmin);
    navigationShell.goBranch(
      shellIndex,
      initialLocation: shellIndex == navigationShell.currentIndex,
    );
  }

  // Shell branches: 0=Assets, 1=Requests, 2=Admin, 3=Settings
  // Display for admin: 0=Assets, 1=Requests, 2=Admin, 3=Settings
  // Display for non-admin: 0=Assets, 1=Requests, 2=Settings (Admin hidden)
  int _shellIndexToDisplayIndex(int shellIndex, bool isAdmin) {
    if (isAdmin) return shellIndex;
    // Non-admin: Settings (shell 3) becomes display 2
    return shellIndex == 3 ? 2 : shellIndex;
  }

  int _displayIndexToShellIndex(int displayIndex, bool isAdmin) {
    if (isAdmin) return displayIndex;
    // Non-admin: display 2 (Settings) maps to shell 3
    return displayIndex == 2 ? 3 : displayIndex;
  }

  List<NavigationDestination> _buildBarDestinations(bool isAdmin) {
    return [
      const NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Assets',
      ),
      const NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: 'Requests',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
  }

  List<NavigationRailDestination> _buildRailDestinations(bool isAdmin) {
    return [
      const NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: Text('Assets'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: Text('Requests'),
      ),
      if (isAdmin)
        const NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: Text('Admin'),
        ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
    ];
  }
}
