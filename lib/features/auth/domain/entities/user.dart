class UserEntity {
  final String id;
  final String mobile;
  final String? name;
  final String? email;
  final String role;

  const UserEntity({
    required this.id,
    required this.mobile,
    this.name,
    this.email,
    required this.role,
  });
}