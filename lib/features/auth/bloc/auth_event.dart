import 'package:supabase_flutter/supabase_flutter.dart';

sealed class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final AuthState authState;
  AuthStateChanged(this.authState);
}

class SendOtpRequested extends AuthEvent {
  final String email;
  SendOtpRequested(this.email);
}

class VerifyOtpRequested extends AuthEvent {
  final String email;
  final String token;
  VerifyOtpRequested({required this.email, required this.token});
}

class SignOutRequested extends AuthEvent {}

class CancelOtpRequested extends AuthEvent {}
