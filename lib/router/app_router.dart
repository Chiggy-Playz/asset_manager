import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/asset_requests_repository.dart';
import '../features/admin/presentation/pages/admin_page.dart';
import '../features/admin/presentation/pages/audit_logs_page.dart';
import '../features/requests/bloc/asset_requests_bloc.dart';
import '../features/admin/presentation/pages/field_options_page.dart';
import '../features/admin/presentation/pages/locations_page.dart';
import '../features/admin/presentation/pages/requests_management_page.dart';
import '../features/admin/presentation/pages/users_page.dart';
import '../features/assets/presentation/pages/asset_detail_page.dart';
import '../features/assets/presentation/pages/asset_form_page.dart';
import '../features/assets/presentation/pages/assets_page.dart';
import '../features/requests/presentation/pages/requests_page.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/otp_verify_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/profile/bloc/profile_state.dart';
import '../features/profile/presentation/pages/profile_creation_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import 'routes.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter({
  required AuthBloc authBloc,
  required ProfileBloc profileBloc,
}) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: GoRouterRefreshStream(
      StreamGroup.merge([authBloc.stream, profileBloc.stream]),
    ),
    redirect: (context, state) {
      final authState = authBloc.state;
      final profileState = profileBloc.state;
      final location = state.matchedLocation;

      // Still initializing
      if (authState is AuthInitial) {
        return location == Routes.splash ? null : Routes.splash;
      }

      final isLoggedIn = authState is Authenticated;
      final isLoading = authState is AuthLoading;
      final isOtpSent = authState is AuthOtpSent;
      final hasProfile = profileState is ProfileLoaded;
      final profileLoading = profileState is ProfileLoading;

      // Allow loading states
      if (isLoading || profileLoading) return null;

      // Auth flow states (OTP sent, waiting for verification)
      if (isOtpSent) {
        return location == Routes.otpVerify ? null : Routes.otpVerify;
      }

      // Not logged in - go to login
      if (!isLoggedIn) {
        return location == Routes.login ? null : Routes.login;
      }

      // Logged in but profile state needs to be checked
      if (profileState is ProfileInitial || profileState is ProfileLoading) {
        return null; // Let it load
      }

      // Logged in but no profile - go to create profile
      if (!hasProfile) {
        return location == Routes.createProfile ? null : Routes.createProfile;
      }

      // Fully authenticated - redirect away from auth pages
      if ([
        Routes.login,
        Routes.otpVerify,
        Routes.createProfile,
        Routes.splash,
      ].contains(location)) {
        return Routes.assets;
      }

      // Redirect /home to /home/assets
      if (location == Routes.home) {
        return Routes.assets;
      }

      // Non-admins cannot access admin pages
      if (location.startsWith(Routes.admin)) {
        final isAdmin =
            // ignore: unnecessary_type_check
            profileState is ProfileLoaded && profileState.profile.isAdmin;
        if (!isAdmin) {
          return Routes.assets;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.otpVerify,
        builder: (context, state) => const OtpVerifyPage(),
      ),
      GoRoute(
        path: Routes.createProfile,
        builder: (context, state) => const ProfileCreationPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.assets,
                builder: (context, state) => const AssetsPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const AssetFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => AssetDetailPage(
                      assetId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => AssetFormPage(
                          assetId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.requests,
                builder: (context, state) => BlocProvider(
                  create: (_) => AssetRequestsBloc(
                    repository: AssetRequestsRepository(),
                  ),
                  child: const RequestsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.admin,
                builder: (context, state) => const AdminPage(),
                routes: [
                  GoRoute(
                    path: 'users',
                    builder: (context, state) => const UsersPage(),
                  ),
                  GoRoute(
                    path: 'locations',
                    builder: (context, state) => const LocationsPage(),
                  ),
                  GoRoute(
                    path: 'field-options',
                    builder: (context, state) => const FieldOptionsPage(),
                  ),
                  GoRoute(
                    path: 'requests',
                    builder: (context, state) => BlocProvider(
                      create: (_) => AssetRequestsBloc(
                        repository: AssetRequestsRepository(),
                      ),
                      child: const RequestsManagementPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'audit-logs',
                    builder: (context, state) => const AuditLogsPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
