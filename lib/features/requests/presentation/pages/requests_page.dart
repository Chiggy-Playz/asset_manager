import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profile/bloc/profile_bloc.dart';
import '../../../profile/bloc/profile_state.dart';
import 'my_requests_page.dart';
import 'pending_requests_page.dart';

/// Wrapper page that shows different content based on user role:
/// - Admins see pending requests that need review
/// - Non-admins see their own requests
class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final isAdmin = state is ProfileLoaded && state.profile.isAdmin;

        if (isAdmin) {
          return const PendingRequestsPage();
        }

        return const MyRequestsPage();
      },
    );
  }
}
