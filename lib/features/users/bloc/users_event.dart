sealed class UsersEvent {}

class UsersFetchRequested extends UsersEvent {}

class UserInviteRequested extends UsersEvent {
  final String email;
  UserInviteRequested(this.email);
}

class UserBanRequested extends UsersEvent {
  final String userId;
  UserBanRequested(this.userId);
}

class UserUnbanRequested extends UsersEvent {
  final String userId;
  UserUnbanRequested(this.userId);
}
