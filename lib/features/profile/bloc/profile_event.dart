sealed class ProfileEvent {}

class ProfileFetchRequested extends ProfileEvent {
  final String userId;
  ProfileFetchRequested(this.userId);
}

class ProfileCreateRequested extends ProfileEvent {
  final String userId;
  final String name;
  ProfileCreateRequested({required this.userId, required this.name});
}

class ProfileUpdateRequested extends ProfileEvent {
  final String userId;
  final String name;
  ProfileUpdateRequested({required this.userId, required this.name});
}

class ProfileCleared extends ProfileEvent {}
