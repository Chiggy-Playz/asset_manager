import '../../../data/models/profile_model.dart';

sealed class UsersState {}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<ProfileModel> users;
  UsersLoaded(this.users);
}

class UsersError extends UsersState {
  final String message;
  UsersError(this.message);
}

class UserActionInProgress extends UsersState {
  final List<ProfileModel> users;
  final String? actionUserId;
  UserActionInProgress(this.users, {this.actionUserId});
}

class UserActionSuccess extends UsersState {
  final List<ProfileModel> users;
  final String message;
  UserActionSuccess(this.users, this.message);
}
