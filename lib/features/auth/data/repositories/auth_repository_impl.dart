import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  AuthRepositoryImpl(this._api, this._storage);

  @override
  Future<bool> requestOtp(String mobile) async {
    final data = await _api.post('/auth/request-otp', {
      'mobile': mobile,
      'appType': 'CUSTOMER',
    });
    // Backend returns { success, isNewUser, message }
    return data['isNewUser'] as bool? ?? false;
  }

  @override
  Future<void> resendOtp(String mobile) async {
    await _api.post('/auth/resend-otp', {
      'mobile': mobile,
      'retryType': 'text',
    });
  }

  @override
  Future<({UserEntity user, bool isNewUser})> requestAndVerifyOtp({
    required String mobile,
    required String otp,
  }) async {
    final data = await _api.post('/auth/verify-otp', {
      'mobile': mobile,
      'otp': otp,
    });

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final isNewUser = data['isNewUser'] as bool? ?? false;

    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await _storage.saveUser(
      id: user.id,
      name: user.name,
      mobile: user.mobile,
      role: user.role,
    );

    return (user: user as UserEntity, isNewUser: isNewUser);
  }

  @override
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', {});
    } catch (_) {}
    await _storage.clear();
  }

  @override
  Future<UserEntity?> getMe() async {
    try {
      final data = await _api.get('/auth/me');
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserEntity> updateProfile({String? name, String? email}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    final data = await _api.patch('/auth/profile', body);
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.saveUser(
      id: user.id,
      name: user.name,
      mobile: user.mobile,
      role: user.role,
    );
    return user;
  }

  @override
  bool get isLoggedIn => _storage.isLoggedIn;

  @override
  String? get savedUserName => _storage.userName;

  @override
  String? get savedUserMobile => _storage.userMobile;
}