import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(ProfileInitial()) {
    on<ProfileFetchRequested>(_onProfileFetchRequested);
    on<ProfileCreateRequested>(_onProfileCreateRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileCleared>(_onProfileCleared);
  }

  Future<void> _onProfileFetchRequested(
    ProfileFetchRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await _profileRepository.fetchProfile(event.userId);
      if (profile != null) {
        emit(ProfileLoaded(profile));
      } else {
        emit(ProfileNotFound());
      }
    } catch (e) {
      emit(ProfileError('Failed to fetch profile'));
    }
  }

  Future<void> _onProfileCreateRequested(
    ProfileCreateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await _profileRepository.createProfile(
        userId: event.userId,
        name: event.name,
      );
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError('Failed to create profile'));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await _profileRepository.updateProfile(
        userId: event.userId,
        name: event.name,
      );
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError('Failed to update profile'));
    }
  }

  Future<void> _onProfileCleared(
    ProfileCleared event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileInitial());
  }
}
