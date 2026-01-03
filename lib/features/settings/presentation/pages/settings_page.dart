import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../profile/bloc/profile_bloc.dart';
import '../../../profile/bloc/profile_event.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ResponsiveBuilder(
        builder: (context, screenSize) {
          final content = ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () {
                  context.read<ProfileBloc>().add(ProfileCleared());
                  context.read<AuthBloc>().add(SignOutRequested());
                },
              ),
            ],
          );

          if (screenSize == ScreenSize.mobile) {
            return content;
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: content,
            ),
          );
        },
      ),
    );
  }
}
