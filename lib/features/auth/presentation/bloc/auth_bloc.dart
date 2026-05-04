import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/services/notification_service.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(const AuthInitial()) {
    on<AuthCheckSessionEvent>(_checkSession);
    on<AuthRequestOtpEvent>(_requestOtp);
    on<AuthResendOtpEvent>(_resendOtp);
    on<AuthVerifyOtpEvent>(_verifyOtp);
    on<AuthLogoutEvent>(_logout);
    on<AuthUpdateProfileEvent>(_updateProfile);
  }

  // ── Check existing session on app start ───────────────────────────────────
  Future<void> _checkSession(
      AuthCheckSessionEvent e, Emitter<AuthState> emit) async {
    if (_repo.isLoggedIn) {
      final user = await _repo.getMe();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
        // Re-register FCM token for returning logged-in user
        _registerFcmToken();
      } else {
        emit(const AuthUnauthenticated());
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  // ── Request OTP ───────────────────────────────────────────────────────────
  Future<void> _requestOtp(
      AuthRequestOtpEvent e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final isNewUser = await _repo.requestOtp(e.mobile);
      if (isNewUser) {
        emit(AuthNewUserDetected(e.mobile));
      } else {
        emit(AuthOtpSent(e.mobile));
      }
    } on ApiException catch (ex) {
      emit(AuthError(ex.message));
    } catch (_) {
      emit(const AuthError('Failed to send OTP. Check your connection.'));
    }
  }

  // ── Resend OTP ────────────────────────────────────────────────────────────
  Future<void> _resendOtp(
      AuthResendOtpEvent e, Emitter<AuthState> emit) async {
    try {
      await _repo.resendOtp(e.mobile);
      emit(AuthOtpResent(e.mobile));
    } on ApiException catch (ex) {
      emit(AuthError(ex.message));
    } catch (_) {
      emit(const AuthError('Failed to resend OTP.'));
    }
  }

  // ── Verify OTP & Login ────────────────────────────────────────────────────
  Future<void> _verifyOtp(
      AuthVerifyOtpEvent e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final result = await _repo.requestAndVerifyOtp(
        mobile: e.mobile,
        otp:    e.otp,
      );
      emit(AuthAuthenticated(user: result.user, isNewUser: result.isNewUser));

      // Register FCM token now that auth token is saved
      _registerFcmToken();

    } on ApiException catch (ex) {
      emit(AuthError(ex.message));
    } catch (_) {
      emit(const AuthError('Verification failed. Try again.'));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _logout(AuthLogoutEvent e, Emitter<AuthState> emit) async {
    await _repo.logout();
    emit(const AuthUnauthenticated());
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  Future<void> _updateProfile(
      AuthUpdateProfileEvent e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.updateProfile(name: e.name, email: e.email);
      emit(AuthAuthenticated(user: user));
    } on ApiException catch (ex) {
      emit(AuthError(ex.message));
    } catch (_) {
      emit(const AuthError('Profile update failed.'));
    }
  }

  // ── FCM Token Registration ────────────────────────────────────────────────
  void _registerFcmToken() {
    NotificationService.instance.registerTokenAfterLogin().catchError((e) {
      debugPrint('[FCM] Token registration failed: $e');
    });
  }
}