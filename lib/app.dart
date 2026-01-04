import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/asset_requests_repository.dart';
import 'data/repositories/assets_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/field_options_repository.dart';
import 'data/repositories/locations_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/users_repository.dart';
import 'features/admin/bloc/field_options_bloc.dart';
import 'features/admin/bloc/locations_bloc.dart';
import 'features/assets/bloc/assets_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/profile/bloc/profile_bloc.dart';
import 'features/profile/bloc/profile_event.dart';
import 'features/requests/bloc/asset_requests_bloc.dart';
import 'features/admin/bloc/users_bloc.dart';
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
  late final LocationsRepository _locationsRepository;
  late final AssetsRepository _assetsRepository;
  late final FieldOptionsRepository _fieldOptionsRepository;
  late final AssetRequestsRepository _assetRequestsRepository;
  late final AuthBloc _authBloc;
  late final ProfileBloc _profileBloc;
  late final UsersBloc _usersBloc;
  late final LocationsBloc _locationsBloc;
  late final AssetsBloc _assetsBloc;
  late final FieldOptionsBloc _fieldOptionsBloc;
  late final AssetRequestsBloc _assetRequestsBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _profileRepository = ProfileRepository();
    _usersRepository = UsersRepository();
    _locationsRepository = LocationsRepository();
    _assetsRepository = AssetsRepository();
    _fieldOptionsRepository = FieldOptionsRepository();
    _assetRequestsRepository = AssetRequestsRepository();
    _authBloc = AuthBloc(authRepository: _authRepository);
    _profileBloc = ProfileBloc(profileRepository: _profileRepository);
    _usersBloc = UsersBloc(usersRepository: _usersRepository);
    _locationsBloc = LocationsBloc(locationsRepository: _locationsRepository);
    _assetsBloc = AssetsBloc(assetsRepository: _assetsRepository);
    _fieldOptionsBloc = FieldOptionsBloc(repository: _fieldOptionsRepository);
    _assetRequestsBloc = AssetRequestsBloc(repository: _assetRequestsRepository);
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
    _locationsBloc.close();
    _assetsBloc.close();
    _fieldOptionsBloc.close();
    _assetRequestsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _profileBloc),
        BlocProvider.value(value: _usersBloc),
        BlocProvider.value(value: _locationsBloc),
        BlocProvider.value(value: _assetsBloc),
        BlocProvider.value(value: _fieldOptionsBloc),
        BlocProvider.value(value: _assetRequestsBloc),
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
