import '../entities/user.dart';

abstract class AuthRepository {
  Future<({UserEntity user, bool isNewUser})> requestAndVerifyOtp({
    required String mobile,
    required String otp,
  });

  /// Returns true if this is a new (unregistered) number
  Future<bool> requestOtp(String mobile);

  Future<void> resendOtp(String mobile);

  Future<void> logout();

  Future<UserEntity?> getMe();

  Future<UserEntity> updateProfile({String? name, String? email});

  bool get isLoggedIn;
  String? get savedUserName;
  String? get savedUserMobile;
}