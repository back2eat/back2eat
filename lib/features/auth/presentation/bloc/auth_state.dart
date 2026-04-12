import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// OTP sent to existing user — show OTP input
class AuthOtpSent extends AuthState {
  final String mobile;
  const AuthOtpSent(this.mobile);
  @override
  List<Object?> get props => [mobile];
}

class AuthOtpResent extends AuthState {
  final String mobile;
  const AuthOtpResent(this.mobile);
  @override
  List<Object?> get props => [mobile];
}

/// OTP sent but number is new — redirect to signup, passing mobile
class AuthNewUserDetected extends AuthState {
  final String mobile;
  const AuthNewUserDetected(this.mobile);
  @override
  List<Object?> get props => [mobile];
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  final bool isNewUser;
  const AuthAuthenticated({required this.user, this.isNewUser = false});
  @override
  List<Object?> get props => [user, isNewUser];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}