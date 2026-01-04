import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/profile_model.dart';
import '../../../data/repositories/users_repository.dart';
import 'users_event.dart';
import 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository _usersRepository;
  List<ProfileModel> _cachedUsers = [];

  UsersBloc({required UsersRepository usersRepository})
      : _usersRepository = usersRepository,
        super(UsersInitial()) {
    on<UsersFetchRequested>(_onFetchRequested);
    on<UserInviteRequested>(_onInviteRequested);
    on<UserBanRequested>(_onBanRequested);
    on<UserUnbanRequested>(_onUnbanRequested);
  }

  Future<void> _onFetchRequested(
    UsersFetchRequested event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());
    try {
      final users = await _usersRepository.fetchAllProfiles();
      _cachedUsers = users;
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onInviteRequested(
    UserInviteRequested event,
    Emitter<UsersState> emit,
  ) async {
    emit(UserActionInProgress(_cachedUsers));
    try {
      await _usersRepository.inviteUser(event.email);
      emit(UserActionSuccess(_cachedUsers, 'Invitation sent to ${event.email}'));
      add(UsersFetchRequested());
    } catch (e) {
      emit(UsersError(e.toString()));
      emit(UsersLoaded(_cachedUsers));
    }
  }

  Future<void> _onBanRequested(
    UserBanRequested event,
    Emitter<UsersState> emit,
  ) async {
    emit(UserActionInProgress(_cachedUsers, actionUserId: event.userId));
    try {
      await _usersRepository.banUser(event.userId);
      emit(UserActionSuccess(_cachedUsers, 'User has been disabled'));
      add(UsersFetchRequested());
    } catch (e) {
      emit(UsersError(e.toString()));
      emit(UsersLoaded(_cachedUsers));
    }
  }

  Future<void> _onUnbanRequested(
    UserUnbanRequested event,
    Emitter<UsersState> emit,
  ) async {
    emit(UserActionInProgress(_cachedUsers, actionUserId: event.userId));
    try {
      await _usersRepository.unbanUser(event.userId);
      emit(UserActionSuccess(_cachedUsers, 'User has been enabled'));
      add(UsersFetchRequested());
    } catch (e) {
      emit(UsersError(e.toString()));
      emit(UsersLoaded(_cachedUsers));
    }
  }
}
