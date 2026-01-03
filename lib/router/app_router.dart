import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/assets/presentation/pages/assets_page.dart';
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
import '../features/users/presentation/pages/users_page.dart';
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
      final isMagicLinkSent = authState is AuthMagicLinkSent;
      final hasProfile = profileState is ProfileLoaded;
      final profileLoading = profileState is ProfileLoading;

      // Allow loading states
      if (isLoading || profileLoading) return null;

      // Auth flow states (OTP sent, waiting for magic link)
      if (isOtpSent) {
        return location == Routes.otpVerify ? null : Routes.otpVerify;
      }
      if (isMagicLinkSent) {
        return location == Routes.login ? null : Routes.login;
      }

      // Not logged in - go to login
      if (!isLoggedIn) {
        return [Routes.login, Routes.otpVerify].contains(location)
            ? null
            : Routes.login;
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

      // Non-admins cannot access users page
      if (location == Routes.users) {
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
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.users,
                builder: (context, state) => const UsersPage(),
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
