import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/users_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/profile/bloc/profile_bloc.dart';
import 'features/profile/bloc/profile_event.dart';
import 'features/users/bloc/users_bloc.dart';
import 'router/app_router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthRepository _authRepository;
  late final ProfileRepository _profileRepository;
  late final UsersRepository _usersRepository;
  late final AuthBloc _authBloc;
  late final ProfileBloc _profileBloc;
  late final UsersBloc _usersBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _profileRepository = ProfileRepository();
    _usersRepository = UsersRepository();
    _authBloc = AuthBloc(authRepository: _authRepository);
    _profileBloc = ProfileBloc(profileRepository: _profileRepository);
    _usersBloc = UsersBloc(usersRepository: _usersRepository);
    _router = createAppRouter(authBloc: _authBloc, profileBloc: _profileBloc);

    // Listen to auth state changes to fetch profile when authenticated
    _authBloc.stream.listen((state) {
      if (state is Authenticated) {
        _profileBloc.add(ProfileFetchRequested(state.user.id));
      }
    });
  }

  @override
  void dispose() {
    _router.dispose();
    _authBloc.close();
    _profileBloc.close();
    _usersBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _profileBloc),
        BlocProvider.value(value: _usersBloc),
      ],
      child: MaterialApp.router(
        title: 'Asset Manager',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
