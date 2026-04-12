import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthRequestOtpEvent extends AuthEvent {
  final String mobile;
  const AuthRequestOtpEvent(this.mobile);
  @override
  List<Object?> get props => [mobile];
}

class AuthResendOtpEvent extends AuthEvent {
  final String mobile;
  const AuthResendOtpEvent(this.mobile);
  @override
  List<Object?> get props => [mobile];
}

class AuthVerifyOtpEvent extends AuthEvent {
  final String mobile;
  final String otp;
  const AuthVerifyOtpEvent({required this.mobile, required this.otp});
  @override
  List<Object?> get props => [mobile, otp];
}

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

class AuthCheckSessionEvent extends AuthEvent {
  const AuthCheckSessionEvent();
}

class AuthUpdateProfileEvent extends AuthEvent {
  final String? name;
  final String? email;
  const AuthUpdateProfileEvent({this.name, this.email});
  @override
  List<Object?> get props => [name, email];
}