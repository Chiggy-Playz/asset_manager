import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authStateSubscription;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<SendOtpRequested>(_onSendOtpRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<CancelOtpRequested>(_onCancelOtpRequested);

    _subscribeToAuthChanges();
  }

  void _subscribeToAuthChanges() {
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (authState) => add(AuthStateChanged(authState)),
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    final session = event.authState.session;
    if (session != null) {
      emit(Authenticated(session.user));
    } else {
      // Only emit Unauthenticated if we're not in a sending OTP state
      if (state is! AuthOtpSent) {
        emit(Unauthenticated());
      }
    }
  }

  Future<void> _onSendOtpRequested(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendOtp(event.email);
      emit(AuthOtpSent(event.email));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Failed to send OTP'));
    }
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.verifyOtp(
        email: event.email,
        token: event.token,
      );
      if (response.user != null) {
        emit(Authenticated(response.user!));
      } else {
        emit(AuthError('Verification failed'));
        emit(AuthOtpSent(event.email)); // Stay on OTP page
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
      emit(AuthOtpSent(event.email)); // Stay on OTP page
    } catch (e) {
      emit(AuthError('Failed to verify OTP'));
      emit(AuthOtpSent(event.email)); // Stay on OTP page
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Failed to sign out'));
    }
  }

  void _onCancelOtpRequested(
    CancelOtpRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(Unauthenticated());
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
